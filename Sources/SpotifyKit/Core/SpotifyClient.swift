import Foundation

/// The main client for interacting with the Spotify Web API.
///
/// SpotifyClient is an actor that provides thread-safe access to all Spotify API endpoints.
/// It handles authentication, token management, and request execution.
///
/// ## Creating a Client
///
/// Use one of the factory methods to create a client:
///
/// ```swift
/// // PKCE for mobile/public apps
/// let client = SpotifyClient.pkce(
///     clientID: "your-client-id",
///     redirectURI: URL(string: "myapp://callback")!,
///     scopes: [.userReadPrivate, .playlistModifyPublic]
/// )
///
/// // Authorization Code for confidential apps
/// let client = SpotifyClient.authorizationCode(
///     clientID: "your-client-id",
///     clientSecret: "your-client-secret",
///     redirectURI: URL(string: "https://myapp.com/callback")!,
///     scopes: [.userReadPrivate]
/// )
///
/// // Client Credentials for app-only access
/// let client = SpotifyClient.clientCredentials(
///     clientID: "your-client-id",
///     clientSecret: "your-client-secret"
/// )
/// ```
///
/// ## Accessing API Endpoints
///
/// The client provides access to all Spotify API services:
///
/// ```swift
/// let profile = try await client.me()
/// let album = try await client.albums.get("album-id")
/// let playlists = try await client.playlists.myPlaylists()
/// ```
///
/// ## Configuration
///
/// Customize client behavior with ``SpotifyClientConfiguration``:
///
/// ```swift
/// let config = SpotifyClientConfiguration.default
///     .withRequestTimeout(60)
///     .withMaxRateLimitRetries(3)
/// let client = SpotifyClient.pkce(..., configuration: config)
/// ```
///
/// ## Advanced Features
///
/// - Request interceptors for logging and analytics
/// - Token expiration and refresh event callbacks for monitoring auth lifecycle
/// - Rate limit monitoring for proactive throttling
/// - Automatic rate limit handling with retry-after support
/// - Thread-safe token management
/// - Request deduplication for concurrent identical calls
/// - Offline mode for cache-only data access
///
/// ### Token Refresh Events
///
/// Monitor the complete token refresh lifecycle with three callback types:
///
/// ```swift
/// // Called before refresh starts - useful for showing loading indicators
/// client.onTokenRefreshWillStart { info in
///     print("🔄 Refreshing token (reason: \(info.reason))")
///     if info.secondsUntilExpiration < 0 {
///         print("Token expired \(-info.secondsUntilExpiration)s ago")
///     }
/// }
///
/// // Called after successful refresh - persist new tokens or update UI
/// client.onTokenRefreshDidSucceed { newTokens in
///     print("✅ Token refreshed, expires at \(newTokens.expiresAt)")
///     Task {
///         await keychain.save(newTokens)
///     }
/// }
///
/// // Called when refresh fails - handle re-authentication
/// client.onTokenRefreshDidFail { error in
///     print("❌ Refresh failed: \(error)")
///     if case SpotifyAuthError.missingRefreshToken = error {
///         Task { @MainActor in
///             showLoginScreen()
///         }
///     }
/// }
/// ```
///
/// ### Offline Mode
///
/// Enable offline mode to block network requests and force cache-only data access:
///
/// ```swift
/// // Enable offline mode
/// await client.setOffline(true)
///
/// // Attempting requests will throw SpotifyClientError.offline
/// do {
///     let album = try await client.albums.get("album-id")
/// } catch SpotifyClientError.offline {
///     print("Cannot fetch - showing cached data only")
///     // Fall back to cached data from your persistence layer
/// }
///
/// // Check offline status
/// if await client.isOffline() {
///     // Show "Offline Mode" indicator in UI
/// }
///
/// // Re-enable network requests
/// await client.setOffline(false)
/// ```
///
/// ## Token Storage
///
/// By default, tokens are stored securely:
/// - **Apple platforms (iOS, macOS, tvOS, watchOS)**: Keychain via ``KeychainTokenStore``
/// - **Linux and other platforms**: Restricted file with 0600 permissions via ``RestrictedFileTokenStore``
///
/// The default store is accessed via ``TokenStoreFactory/defaultStore(service:account:)``.
///
/// ### Custom Token Storage
///
/// Override the default by providing a custom ``TokenStore`` implementation:
///
/// ```swift
/// // Example: In-memory store for testing
/// actor MemoryStore: TokenStore {
///     private var tokens: SpotifyTokens?
///
///     func load() async throws -> SpotifyTokens? { tokens }
///     func save(_ tokens: SpotifyTokens) async throws { self.tokens = tokens }
///     func clear() async throws { self.tokens = nil }
/// }
///
/// let client = SpotifyClient.pkce(
///     clientID: "...",
///     redirectURI: URL(string: "myapp://callback")!,
///     scopes: [.userReadPrivate],
///     tokenStore: MemoryStore()
/// )
/// ```
///
/// Common custom implementations include:
/// - App Groups for sharing tokens between extensions
/// - CloudKit or iCloud for multi-device sync
/// - Server-side storage for web apps
///
/// - SeeAlso: ``SpotifyClientConfiguration``, ``RequestInterceptor``, ``TokenExpirationCallback``, ``TokenRefreshCallbacks``
public actor SpotifyClient<Capability: Sendable> {
    let httpClient: HTTPClient
    private let backend: TokenGrantAuthenticator
    let configuration: SpotifyClientConfiguration
    var interceptors: [RequestInterceptor] = []

    /// Centralized event manager for lifecycle and instrumentation callbacks.
    public let events = SpotifyClientEvents()

    let networkRecovery: NetworkRecoveryHandler
    var ongoingRequests: [String: Task<(any Sendable), Error>] = [:]
    var _isOffline: Bool = false

    /// The logger instance for this client.
    internal let logger: DebugLogger

    init(
        backend: TokenGrantAuthenticator,
        httpClient: HTTPClient = URLSessionHTTPClient(),
        configuration: consuming SpotifyClientConfiguration = .default
    ) {
        do {
            try configuration.validate()
        } catch {
            preconditionFailure("Invalid SpotifyClientConfiguration: \(error)")
        }
        self.backend = backend
        self.httpClient = httpClient
        self.configuration = configuration
        self.networkRecovery = NetworkRecoveryHandler(configuration: configuration.networkRecovery)
        self.logger = DebugLogger()

        Task {
            await logger.configure(configuration.debug)
        }
    }

    /// Add a request interceptor.
    ///
    /// Interceptors are called in the order they were added.
    ///
    /// ```swift
    /// client.addInterceptor { request in
    ///     print("📤 \(request.httpMethod ?? "GET") \(request.url?.path ?? "")")
    ///     return request
    /// }
    /// ```
    public func addInterceptor(_ interceptor: @escaping RequestInterceptor) {
        interceptors.append(interceptor)
    }

    /// Remove all interceptors.
    public func removeAllInterceptors() {
        interceptors.removeAll()
    }

    /// Register a ``SpotifyClientObserver`` to receive instrumentation events.
    @discardableResult
    public func addObserver(_ observer: SpotifyClientObserver) async -> DebugLogObserver {
        return await logger.addObserver(observer)
    }

    /// Remove a previously registered instrumentation observer.
    public func removeObserver(_ token: DebugLogObserver) async {
        await logger.removeObserver(token)
    }

    /// Set a callback to be notified of token expiration.
    ///
    /// The callback receives the number of seconds until expiration.
    ///
    /// ```swift
    /// client.events.onTokenExpiring { expiresIn in
    ///     if expiresIn < 300 {
    ///         print("⚠️ Token expires in \(expiresIn) seconds")
    ///     }
    /// }
    /// ```
    @available(*, deprecated, message: "Use client.events.onTokenExpiring instead")
    public func onTokenExpiring(_ callback: @escaping TokenExpirationCallback) {
        Task { await events.onTokenExpiring(callback) }
    }

    /// Set a callback to be notified before a token refresh begins.
    ///
    /// The callback receives information about why the refresh is happening and when
    /// the current token expires.
    ///
    /// ```swift
    /// client.events.onTokenRefreshWillStart { info in
    ///     if info.reason == .automatic {
    ///         print("🔄 Auto-refreshing token (expires in \(info.secondsUntilExpiration)s)")
    ///     }
    /// }
    /// ```
    @available(*, deprecated, message: "Use client.events.onTokenRefreshWillStart instead")
    public func onTokenRefreshWillStart(_ callback: @escaping TokenRefreshWillStartCallback) {
        Task { await events.onTokenRefreshWillStart(callback) }
    }

    /// Set a callback to be notified when a token refresh succeeds.
    ///
    /// The callback receives the new tokens, including the refreshed access token
    /// and its expiration date.
    ///
    /// ```swift
    /// client.events.onTokenRefreshDidSucceed { newTokens in
    ///     print("✅ Token refreshed, expires at \(newTokens.expiresAt)")
    ///     await keychain.save(newTokens)
    /// }
    /// ```
    @available(*, deprecated, message: "Use client.events.onTokenRefreshDidSucceed instead")
    public func onTokenRefreshDidSucceed(_ callback: @escaping TokenRefreshDidSucceedCallback) {
        Task { await events.onTokenRefreshDidSucceed(callback) }
    }

    /// Set a callback to be notified when a token refresh fails.
    ///
    /// Use this to handle authentication failures, such as showing a login screen
    /// when the refresh token is invalid or expired.
    ///
    /// ```swift
    /// client.events.onTokenRefreshDidFail { error in
    ///     if case SpotifyAuthError.missingRefreshToken = error {
    ///         Task { @MainActor in
    ///             showLoginScreen()
    ///         }
    ///     }
    /// }
    /// ```
    @available(*, deprecated, message: "Use client.events.onTokenRefreshDidFail instead")
    public func onTokenRefreshDidFail(_ callback: @escaping TokenRefreshDidFailCallback) {
        Task { await events.onTokenRefreshDidFail(callback) }
    }

    /// Set a callback to receive rate limit information from API responses.
    ///
    /// The callback receives rate limit headers from each API response, allowing you to
    /// implement proactive throttling or display usage warnings.
    ///
    /// ```swift
    /// client.events.onRateLimitInfo { info in
    ///     if let remaining = info.remaining, remaining < 10 {
    ///         print("⚠️ Only \(remaining) requests remaining!")
    ///     }
    ///
    ///     if let resetDate = info.resetDate {
    ///         let secondsUntilReset = resetDate.timeIntervalSinceNow
    ///         print("Rate limit resets in \(Int(secondsUntilReset))s")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter callback: A closure called with rate limit info from each response.
    @available(*, deprecated, message: "Use client.events.onRateLimitInfo instead")
    public nonisolated func onRateLimitInfo(_ callback: @escaping RateLimitInfoCallback) {
        Task { await events.onRateLimitInfo(callback) }
    }

    /// Check when the current access token expires.
    ///
    /// Returns the number of seconds until the cached token expires, or `nil` if no token is cached.
    /// Use this to display "session expires in..." messaging or to proactively refresh tokens.
    ///
    /// ```swift
    /// if let expiresIn = await client.tokenExpiresIn() {
    ///     if expiresIn < 300 {
    ///         print("⚠️ Token expires in \(Int(expiresIn)) seconds")
    ///         // Optionally refresh proactively
    ///         _ = try? await client.accessToken()
    ///     }
    /// } else {
    ///     print("No token cached yet")
    /// }
    /// ```
    ///
    /// - Returns: Seconds until token expiration, or `nil` if no token is available.
    public func tokenExpiresIn() async -> TimeInterval? {
        guard let tokens = try? await backend.loadPersistedTokens() else {
            return nil
        }
        return tokens.expiresAt.timeIntervalSinceNow
    }

    /// Enable offline mode to prevent network requests.
    ///
    /// When offline mode is enabled, all API requests will throw ``SpotifyClientError/offline``.
    /// This is useful for implementing cache-only functionality or handling network unavailability.
    ///
    /// ```swift
    /// // Enable offline mode
    /// await client.setOffline(true)
    ///
    /// // Attempting requests will now throw
    /// do {
    ///     let album = try await client.albums.get("album-id")
    /// } catch SpotifyClientError.offline {
    ///     print("Cannot fetch - offline mode enabled")
    ///     // Fall back to cached data
    /// }
    ///
    /// // Re-enable network requests
    /// await client.setOffline(false)
    /// ```
    ///
    /// - Parameter offline: `true` to enable offline mode, `false` to allow network requests.
    public func setOffline(_ offline: Bool) {
        _isOffline = offline
    }

    /// Check if the client is in offline mode.
    ///
    /// Returns `true` if offline mode is enabled and network requests will be blocked.
    ///
    /// ```swift
    /// if await client.isOffline() {
    ///     // Show cached data only
    /// } else {
    ///     // Can make network requests
    /// }
    /// ```
    ///
    /// - Returns: `true` if offline mode is enabled, `false` otherwise.
    public func isOffline() -> Bool {
        _isOffline
    }

    // MARK: - Internal auth helper

    /// Helper to get the string token from the backend.
    /// - Parameter invalidatingPrevious: If true, force a refresh/invalidate cache.
    func accessToken(invalidatingPrevious: Bool = false) async throws -> String {
        // Get the old tokens (if any) to detect if a refresh occurred
        let oldTokens = try? await backend.loadPersistedTokens()
        let oldAccessToken = oldTokens?.accessToken

        // Determine refresh reason
        let reason: TokenRefreshInfo.RefreshReason = invalidatingPrevious ? .manual : .automatic
        let secondsUntilExpiration = oldTokens?.expiresAt.timeIntervalSinceNow ?? 0

        // Check if a refresh will happen
        let willRefresh = oldTokens == nil || oldTokens!.isExpired || invalidatingPrevious

        // Notify before refresh (if refresh is about to happen)
        if willRefresh {
            let info = TokenRefreshInfo(
                reason: reason,
                secondsUntilExpiration: secondsUntilExpiration
            )
            await events.invokeTokenRefreshWillStart(info)
            await logger.emit(.tokenRefreshWillStart(info))
        }

        // Attempt to get tokens (may trigger refresh internally)
        do {
            let tokens = try await backend.accessToken(
                invalidatingPrevious: invalidatingPrevious
            )

            // Check if the access token changed (indicating a refresh occurred)
            let didRefresh = oldAccessToken != tokens.accessToken

            // Notify of successful refresh
            if didRefresh {
                await events.invokeTokenRefreshDidSucceed(tokens)
                await logger.emit(.tokenRefreshDidSucceed(tokens))
            }

            // Always notify token expiration callback
            let expiresIn = tokens.expiresAt.timeIntervalSinceNow
            await events.invokeTokenExpiring(expiresIn)

            return tokens.accessToken
        } catch {
            // Notify of refresh failure (if refresh was attempted)
            if willRefresh {
                await events.invokeTokenRefreshDidFail(error)
                await logger.emit(
                    .tokenRefreshDidFail(TokenRefreshFailureContext(error: error))
                )
            }
            throw error
        }
    }
}

// Sugar so you don't have to write the generic everywhere.
public typealias UserSpotifyClient = SpotifyClient<UserAuthCapability>
public typealias AppSpotifyClient = SpotifyClient<AppOnlyAuthCapability>

/// Builder that composes a user-auth capable ``SpotifyClient`` without repeating HTTP client,
/// token store, or configuration plumbing.
public struct SpotifyUserClientBuilder {
    private enum Flow {
        struct PKCEParameters {
            let clientID: String
            let redirectURI: URL
            let scopes: Set<SpotifyScope>
            let showDialog: Bool
            let pkceProvider: PKCEProvider
        }

        struct AuthorizationCodeParameters {
            let clientID: String
            let clientSecret: String
            let redirectURI: URL
            let scopes: Set<SpotifyScope>
            let showDialog: Bool
        }

        case pkce(PKCEParameters)
        case authorizationCode(AuthorizationCodeParameters)
    }

    private var flow: Flow?
    private var tokenStore: TokenStore = TokenStoreFactory.defaultStore()
    private var httpClient: HTTPClient = URLSessionHTTPClient()
    private var configuration: SpotifyClientConfiguration = .default

    public init() {}

    /// Configure the builder for the PKCE flow.
    public func withPKCE(
        clientID: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false,
        pkceProvider: PKCEProvider = DefaultPKCEProvider()
    ) -> SpotifyUserClientBuilder {
        var copy = self
        copy.flow = .pkce(
            Flow.PKCEParameters(
                clientID: clientID,
                redirectURI: redirectURI,
                scopes: scopes,
                showDialog: showDialog,
                pkceProvider: pkceProvider
            )
        )
        return copy
    }

    /// Configure the builder for the authorization code flow.
    public func withAuthorizationCode(
        clientID: String,
        clientSecret: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false
    ) -> SpotifyUserClientBuilder {
        var copy = self
        copy.flow = .authorizationCode(
            Flow.AuthorizationCodeParameters(
                clientID: clientID,
                clientSecret: clientSecret,
                redirectURI: redirectURI,
                scopes: scopes,
                showDialog: showDialog
            )
        )
        return copy
    }

    /// Override the token store (defaults to ``TokenStoreFactory/defaultStore``).
    public func withTokenStore(_ store: TokenStore) -> SpotifyUserClientBuilder {
        var copy = self
        copy.tokenStore = store
        return copy
    }

    /// Override the HTTP client shared by all requests.
    public func withHTTPClient(_ client: HTTPClient) -> SpotifyUserClientBuilder {
        var copy = self
        copy.httpClient = client
        return copy
    }

    /// Override the client configuration (request timeouts, retries, debug logging, ...).
    public func withConfiguration(_ configuration: SpotifyClientConfiguration)
        -> SpotifyUserClientBuilder
    {
        var copy = self
        copy.configuration = configuration
        return copy
    }

    /// Build the configured client. A flow (PKCE or authorization code) must be selected first.
    public func build() -> UserSpotifyClient {
        guard let flow else {
            preconditionFailure(
                "SpotifyUserClientBuilder requires selecting an auth flow via withPKCE(...) or withAuthorizationCode(...)."
            )
        }

        switch flow {
        case .pkce(let params):
            return UserSpotifyClient.pkce(
                clientID: params.clientID,
                redirectURI: params.redirectURI,
                scopes: params.scopes,
                showDialog: params.showDialog,
                tokenStore: tokenStore,
                httpClient: httpClient,
                pkceProvider: params.pkceProvider,
                configuration: configuration
            )
        case .authorizationCode(let params):
            return UserSpotifyClient.authorizationCode(
                clientID: params.clientID,
                clientSecret: params.clientSecret,
                redirectURI: params.redirectURI,
                scopes: params.scopes,
                showDialog: params.showDialog,
                tokenStore: tokenStore,
                httpClient: httpClient,
                configuration: configuration
            )
        }
    }
}

/// Builder that configures an app-only ``SpotifyClient`` using fluent modifiers.
public struct SpotifyAppClientBuilder {
    private struct ClientCredentialsParameters {
        let clientID: String
        let clientSecret: String
        let scopes: Set<SpotifyScope>
    }

    private var flow: ClientCredentialsParameters?
    private var tokenStore: TokenStore?
    private var httpClient: HTTPClient = URLSessionHTTPClient()
    private var configuration: SpotifyClientConfiguration = .default

    public init() {}

    /// Configure the builder for the Client Credentials flow.
    public func withClientCredentials(
        clientID: String,
        clientSecret: String,
        scopes: Set<SpotifyScope> = []
    ) -> SpotifyAppClientBuilder {
        var copy = self
        copy.flow = ClientCredentialsParameters(
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes
        )
        return copy
    }

    /// Override the optional token store backing the authenticator.
    public func withTokenStore(_ store: TokenStore?) -> SpotifyAppClientBuilder {
        var copy = self
        copy.tokenStore = store
        return copy
    }

    /// Override the HTTP client shared by all requests.
    public func withHTTPClient(_ client: HTTPClient) -> SpotifyAppClientBuilder {
        var copy = self
        copy.httpClient = client
        return copy
    }

    /// Override the client configuration (timeouts, retries, logging, ...).
    public func withConfiguration(_ configuration: SpotifyClientConfiguration)
        -> SpotifyAppClientBuilder
    {
        var copy = self
        copy.configuration = configuration
        return copy
    }

    /// Build the configured client. ``withClientCredentials`` must be called first.
    public func build() -> AppSpotifyClient {
        guard let flow else {
            preconditionFailure(
                "SpotifyAppClientBuilder requires client credentials parameters before build().")
        }

        return AppSpotifyClient.clientCredentials(
            clientID: flow.clientID,
            clientSecret: flow.clientSecret,
            scopes: flow.scopes,
            httpClient: httpClient,
            tokenStore: tokenStore,
            configuration: configuration
        )
    }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Returns a builder for composing a user-auth capable ``SpotifyClient``.
    public static func builder() -> SpotifyUserClientBuilder {
        SpotifyUserClientBuilder()
    }

    /// Create a PKCE client for public/mobile apps.
    ///
    /// PKCE (Proof Key for Code Exchange) is the recommended flow for mobile and public apps
    /// that cannot securely store a client secret.
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - redirectURI: The redirect URI registered in your Spotify app settings.
    ///   - scopes: The authorization scopes your app needs.
    ///   - showDialog: Whether to force the user to approve the app again.
    ///   - tokenStore: Storage for persisting tokens (default: file-based).
    ///   - httpClient: HTTP client for making requests.
    ///   - pkceProvider: Provider for generating PKCE challenge/verifier pairs.
    ///   - configuration: Client configuration options.
    /// - Returns: A configured SpotifyClient instance.
    public static func pkce(
        clientID: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false,
        tokenStore: TokenStore = TokenStoreFactory.defaultStore(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        pkceProvider: PKCEProvider = DefaultPKCEProvider(),
        configuration: SpotifyClientConfiguration = .default
    ) -> SpotifyClient {
        let config = SpotifyAuthConfig.pkce(
            clientID: clientID,
            redirectURI: redirectURI,
            scopes: scopes,
            showDialog: showDialog
        )

        let backend = SpotifyPKCEAuthenticator(
            config: config,
            pkceProvider: pkceProvider,
            httpClient: httpClient,
            tokenStore: tokenStore
        )

        return SpotifyClient(backend: backend, httpClient: httpClient, configuration: configuration)
    }

    /// Create an Authorization Code client for confidential apps.
    ///
    /// Authorization Code flow is for server-side apps that can securely store a client secret.
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - clientSecret: Your Spotify application's client secret.
    ///   - redirectURI: The redirect URI registered in your Spotify app settings.
    ///   - scopes: The authorization scopes your app needs.
    ///   - showDialog: Whether to force the user to approve the app again.
    ///   - tokenStore: Storage for persisting tokens (default: file-based).
    ///   - httpClient: HTTP client for making requests.
    ///   - configuration: Client configuration options.
    /// - Returns: A configured SpotifyClient instance.
    public static func authorizationCode(
        clientID: String,
        clientSecret: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false,
        tokenStore: TokenStore = TokenStoreFactory.defaultStore(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        configuration: SpotifyClientConfiguration = .default
    ) -> SpotifyClient {
        let config = SpotifyAuthConfig.authorizationCode(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes,
            showDialog: showDialog
        )

        let backend = SpotifyAuthorizationCodeAuthenticator(
            config: config,
            httpClient: httpClient,
            tokenStore: tokenStore
        )

        return SpotifyClient(backend: backend, httpClient: httpClient, configuration: configuration)
    }
}

extension SpotifyClient where Capability == AppOnlyAuthCapability {

    /// Returns a builder for composing an app-only ``SpotifyClient``.
    public static func builder() -> SpotifyAppClientBuilder {
        SpotifyAppClientBuilder()
    }

    /// Create a Client Credentials client for app-only access.
    ///
    /// Client Credentials flow is for server-to-server authentication without user context.
    /// It provides access to public data only (no user-specific endpoints).
    ///
    /// - Parameters:
    ///   - clientID: Your Spotify application's client ID.
    ///   - clientSecret: Your Spotify application's client secret.
    ///   - scopes: The authorization scopes (usually empty for this flow).
    ///   - httpClient: HTTP client for making requests.
    ///   - tokenStore: Optional storage for persisting tokens.
    ///   - configuration: Client configuration options.
    /// - Returns: A configured SpotifyClient instance.
    public static func clientCredentials(
        clientID: String,
        clientSecret: String,
        scopes: Set<SpotifyScope> = [],
        httpClient: HTTPClient = URLSessionHTTPClient(),
        tokenStore: TokenStore? = nil,
        configuration: SpotifyClientConfiguration = .default
    ) -> SpotifyClient {
        let config = SpotifyAuthConfig.clientCredentials(
            clientID: clientID,
            clientSecret: clientSecret,
            scopes: scopes
        )

        let backend = SpotifyClientCredentialsAuthenticator(
            config: config,
            httpClient: httpClient,
            tokenStore: tokenStore
        )

        return SpotifyClient(backend: backend, httpClient: httpClient, configuration: configuration)
    }
}

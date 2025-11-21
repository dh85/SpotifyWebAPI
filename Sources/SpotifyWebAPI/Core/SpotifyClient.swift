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
/// let config = SpotifyClientConfiguration(
///     requestTimeout: 60,
///     maxRateLimitRetries: 3
/// )
/// let client = SpotifyClient.pkce(..., configuration: config)
/// ```
///
/// ## Advanced Features
///
/// - Request interceptors for logging and analytics
/// - Token expiration callbacks for proactive refresh
/// - Automatic rate limit handling
/// - Thread-safe token management
///
/// - SeeAlso: ``SpotifyClientConfiguration``, ``RequestInterceptor``, ``TokenExpirationCallback``
public actor SpotifyClient<Capability: Sendable> {
    let httpClient: HTTPClient
    private let backend: TokenGrantAuthenticator
    let configuration: SpotifyClientConfiguration
    var interceptors: [RequestInterceptor] = []
    private var tokenExpirationCallback: TokenExpirationCallback?

    init(
        backend: TokenGrantAuthenticator,
        httpClient: HTTPClient = URLSessionHTTPClient(),
        configuration: SpotifyClientConfiguration = .default
    ) {
        self.backend = backend
        self.httpClient = httpClient
        self.configuration = configuration
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
    
    /// Set a callback to be notified of token expiration.
    ///
    /// The callback receives the number of seconds until expiration.
    ///
    /// ```swift
    /// client.onTokenExpiring { expiresIn in
    ///     if expiresIn < 300 {
    ///         print("⚠️ Token expires in \(expiresIn) seconds")
    ///     }
    /// }
    /// ```
    public func onTokenExpiring(_ callback: @escaping TokenExpirationCallback) {
        tokenExpirationCallback = callback
    }

    // MARK: - Internal auth helper

    /// Helper to get the string token from the backend.
    /// - Parameter invalidatingPrevious: If true, force a refresh/invalidate cache.
    func accessToken(invalidatingPrevious: Bool = false) async throws -> String {
        // Pass the flag through to the backend
        let tokens = try await backend.accessToken(
            invalidatingPrevious: invalidatingPrevious
        )
        
        // Notify callback of expiration
        if let callback = tokenExpirationCallback {
            let expiresIn = tokens.expiresAt.timeIntervalSinceNow
            callback(expiresIn)
        }
        
        return tokens.accessToken
    }
}

// Sugar so you don't have to write the generic everywhere.
public typealias UserSpotifyClient = SpotifyClient<UserAuthCapability>
public typealias AppSpotifyClient = SpotifyClient<AppOnlyAuthCapability>

extension SpotifyClient where Capability == UserAuthCapability {

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
        tokenStore: TokenStore = FileTokenStore(),
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
        tokenStore: TokenStore = FileTokenStore(),
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

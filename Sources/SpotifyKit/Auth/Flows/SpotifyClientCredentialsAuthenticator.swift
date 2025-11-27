import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Authenticator for the OAuth 2.0 Client Credentials flow.
///
/// Client Credentials flow is for server-to-server authentication without user context.
/// It provides access to public Spotify data only (no user-specific endpoints like
/// playlists or library). Tokens do not support refresh.
///
/// ## Usage
///
/// ```swift
/// let authenticator = SpotifyClientCredentialsAuthenticator(
///     config: .clientCredentials(
///         clientID: "your-client-id",
///         clientSecret: "your-client-secret"
///     )
/// )
///
/// let tokens = try await authenticator.appAccessToken()
/// ```
///
/// - SeeAlso: ``SpotifyAuthConfig/clientCredentials(clientID:clientSecret:scopes:tokenEndpoint:)``
public actor SpotifyClientCredentialsAuthenticator {
    private let config: SpotifyAuthConfig
    private let httpClient: HTTPClient
    private let tokenStore: TokenStore?
    private var cachedTokens: SpotifyTokens?
    private var refreshTask: Task<SpotifyTokens, Error>?

    public init(
        config: SpotifyAuthConfig,
        httpClient: HTTPClient = URLSessionHTTPClient(),
        tokenStore: TokenStore? = nil
    ) {
        self.config = config
        self.httpClient = httpClient
        self.tokenStore = tokenStore
    }

    // MARK: - Token persistence

    /// Load tokens from persistent storage if available.
    ///
    /// - Returns: The stored tokens, or nil if no token store is configured or no tokens exist.
    /// - Throws: An error if loading fails.
    public func loadPersistedTokens() async throws -> SpotifyTokens? {
        if let cachedTokens {
            return cachedTokens
        }
        guard let tokenStore else {
            return nil
        }
        let stored = try await tokenStore.load()
        cachedTokens = stored
        return stored
    }

    // MARK: - Main API

    /// Get an app-only access token.
    ///
    /// This method returns cached tokens if valid, loads from storage if available,
    /// or requests a new token from Spotify.
    ///
    /// - Parameter invalidatingPrevious: If true, force a new token request even if cached tokens are valid.
    /// - Returns: Valid access tokens.
    /// - Throws: ``SpotifyAuthError`` if token request fails.
    public func appAccessToken(invalidatingPrevious: Bool = false) async throws -> SpotifyTokens {
        // 1. Return from cache if valid and not being invalidated
        if let cachedTokens, !cachedTokens.isExpired, !invalidatingPrevious {
            return cachedTokens
        }

        // Check for ongoing refresh
        if let refreshTask {
            return try await refreshTask.value
        }

        // 2. Return from store if valid and not being invalidated
        if let tokenStore,
            let stored = try await tokenStore.load(),
            !stored.isExpired, !invalidatingPrevious
        {
            cachedTokens = stored
            return stored
        }

        // 3. Otherwise, fetch a fresh token
        let task = Task { () -> SpotifyTokens in
            let fresh = try await self.requestNewAccessToken()
            if let tokenStore = self.tokenStore {
                try await tokenStore.save(fresh)
            }
            self.cachedTokens = fresh
            return fresh
        }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    // MARK: - Internal request/decoding
    private func requestNewAccessToken() async throws -> SpotifyTokens {
        guard let clientSecret = config.clientSecret else {
            throw SpotifyAuthError.unexpectedResponse
        }
        var items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ]
        if !config.scopes.isEmpty {
            items.append(
                URLQueryItem(
                    name: "scope",
                    value: config.scopes.spotifyQueryValue
                )
            )
        }

        let request = makeTokenRequest(
            endpoint: config.tokenEndpoint,
            bodyItems: items,
            basicAuthCredentials: (clientID: config.clientID, clientSecret: clientSecret)
        )
        let response = try await httpClient.data(for: request)
        let tokens = try SpotifyAuthHTTP.decodeTokens(
            from: response.data,
            response: response.urlResponse,
            existingRefreshToken: nil
        )

        // Force `refreshToken` to nil for client credentials.
        return SpotifyTokens(
            accessToken: tokens.accessToken,
            refreshToken: nil,
            expiresAt: tokens.expiresAt,
            scope: tokens.scope,
            tokenType: tokens.tokenType
        )
    }
}

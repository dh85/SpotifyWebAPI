import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Authenticator for the OAuth 2.0 Authorization Code flow.
///
/// Authorization Code flow is for confidential apps (server-side) that can securely
/// store a client secret. It provides access to user-specific data and supports
/// token refresh.
///
/// ## Usage
///
/// ```swift
/// let authenticator = SpotifyAuthorizationCodeAuthenticator(
///     config: .authorizationCode(
///         clientID: "your-client-id",
///         clientSecret: "your-client-secret",
///         redirectURI: URL(string: "https://myapp.com/callback")!,
///         scopes: [.userReadPrivate, .playlistModifyPublic]
///     )
/// )
///
/// // Generate authorization URL
/// let authURL = try authenticator.makeAuthorizationURL()
/// // Open authURL in browser
///
/// // Handle callback
/// let tokens = try await authenticator.handleCallback(callbackURL)
/// ```
///
/// - SeeAlso: ``SpotifyAuthConfig/authorizationCode(clientID:clientSecret:redirectURI:scopes:showDialog:authorizationEndpoint:tokenEndpoint:)``
public actor SpotifyAuthorizationCodeAuthenticator: TokenRefreshing {
    private let config: SpotifyAuthConfig
    private let httpClient: HTTPClient
    private let componentsBuilder: (URL) -> URLComponents?
    private var currentState: String?

    let tokenStore: TokenStore
    var cachedTokens: SpotifyTokens?

    public init(
        config: SpotifyAuthConfig,
        httpClient: HTTPClient = URLSessionHTTPClient(),
        tokenStore: TokenStore = TokenStoreFactory.defaultStore(),
        componentsBuilder: @escaping (URL) -> URLComponents? = {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }
    ) {
        self.config = config
        self.httpClient = httpClient
        self.tokenStore = tokenStore
        self.componentsBuilder = componentsBuilder
    }

    // MARK: - Authorization URL

    /// Generate the authorization URL to present to the user.
    ///
    /// This URL should be opened in a browser. After the user authorizes,
    /// Spotify will redirect to your redirect URI with an authorization code.
    ///
    /// - Returns: The authorization URL.
    public func makeAuthorizationURL() throws -> URL {
        let state = Self.generateState()
        currentState = state

        var components = URLComponents(
            url: config.authorizationEndpoint,
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = buildAuthorizationQueryItems(config: config, state: state)
        return components.url!
    }

    // MARK: - Callback handling

    /// Handle the authorization callback and exchange the code for tokens.
    ///
    /// Call this method when your server receives the redirect from Spotify.
    ///
    /// - Parameter url: The callback URL containing the authorization code.
    /// - Returns: The access and refresh tokens.
    /// - Throws: ``SpotifyAuthError`` if the callback is invalid or token exchange fails.
    public func handleCallback(_ url: URL) async throws -> SpotifyTokens {
        let (code, state) = try parseAuthorizationCallback(
            url, componentsBuilder: componentsBuilder)
        guard let expected = currentState, expected == state else {
            throw SpotifyAuthError.stateMismatch
        }

        currentState = nil

        let tokens = try await exchangeCodeForTokens(code: code)
        try await persist(tokens)
        return tokens
    }

    // MARK: - Refresh

    /// Refresh an expired access token using a refresh token.
    ///
    /// - Parameter refreshToken: The refresh token from a previous authorization.
    /// - Returns: New access and refresh tokens.
    /// - Throws: ``SpotifyAuthError`` if the refresh fails.
    public func refreshAccessToken(refreshToken: String) async throws
        -> SpotifyTokens
    {
        guard let clientSecret = config.clientSecret else {
            throw SpotifyAuthError.unexpectedResponse
        }

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]

        let request = makeTokenRequest(
            endpoint: config.tokenEndpoint,
            bodyItems: items,
            basicAuthCredentials: (clientID: config.clientID, clientSecret: clientSecret)
        )
        let response = try await httpClient.data(for: request)
        return try SpotifyAuthHTTP.decodeTokens(
            from: response.data,
            response: response.urlResponse,
            existingRefreshToken: refreshToken
        )
    }

    // MARK: - Private helpers

    private func exchangeCodeForTokens(code: String) async throws
        -> SpotifyTokens
    {
        guard let clientSecret = config.clientSecret else {
            throw SpotifyAuthError.unexpectedResponse
        }

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(
                name: "redirect_uri",
                value: config.redirectURI.absoluteString
            ),
        ]

        let request = makeTokenRequest(
            endpoint: config.tokenEndpoint,
            bodyItems: items,
            basicAuthCredentials: (clientID: config.clientID, clientSecret: clientSecret)
        )
        let response = try await httpClient.data(for: request)
        return try SpotifyAuthHTTP.decodeTokens(
            from: response.data,
            response: response.urlResponse,
            existingRefreshToken: nil
        )
    }

    private static func generateState() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    #if DEBUG
        func __test_formURLEncodedBody(items: [URLQueryItem]) -> Data {
            SpotifyAuthHTTP.formURLEncodedBody(from: items)
        }
    #endif
}

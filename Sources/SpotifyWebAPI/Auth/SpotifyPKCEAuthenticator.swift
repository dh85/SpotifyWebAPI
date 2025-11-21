import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Authenticator for the OAuth 2.0 PKCE (Proof Key for Code Exchange) flow.
///
/// PKCE is the recommended authorization flow for mobile and public apps that cannot
/// securely store a client secret. It uses a dynamically generated code verifier and
/// challenge to prevent authorization code interception attacks.
///
/// ## Usage
///
/// ```swift
/// let authenticator = SpotifyPKCEAuthenticator(
///     config: .pkce(
///         clientID: "your-client-id",
///         redirectURI: URL(string: "myapp://callback")!,
///         scopes: [.userReadPrivate, .playlistModifyPublic]
///     )
/// )
///
/// // Generate authorization URL
/// let authURL = try authenticator.makeAuthorizationURL()
/// // Open authURL in browser/web view
///
/// // Handle callback
/// let tokens = try await authenticator.handleCallback(callbackURL)
/// ```
///
/// - SeeAlso: ``SpotifyAuthConfig/pkce(clientID:redirectURI:scopes:showDialog:authorizationEndpoint:tokenEndpoint:)``
public actor SpotifyPKCEAuthenticator: TokenRefreshing {
    private let config: SpotifyAuthConfig
    private let pkceProvider: PKCEProvider
    private let httpClient: HTTPClient
    private let componentsBuilder: (URL) -> URLComponents?
    private var currentPKCE: PKCEPair?

    let tokenStore: TokenStore
    var cachedTokens: SpotifyTokens?

    public init(
        config: SpotifyAuthConfig,
        pkceProvider: PKCEProvider = DefaultPKCEProvider(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        tokenStore: TokenStore = FileTokenStore(),
        componentsBuilder: @escaping (URL) -> URLComponents? = {
            URLComponents(url: $0, resolvingAgainstBaseURL: false)
        }
    ) {
        self.config = config
        self.pkceProvider = pkceProvider
        self.httpClient = httpClient
        self.tokenStore = tokenStore
        self.componentsBuilder = componentsBuilder
    }

    // MARK: - Authorization URL

    /// Generate the authorization URL to present to the user.
    ///
    /// This URL should be opened in a browser or web view. After the user authorizes,
    /// Spotify will redirect to your redirect URI with an authorization code.
    ///
    /// - Returns: The authorization URL.
    /// - Throws: An error if PKCE generation fails.
    public func makeAuthorizationURL() throws -> URL {
        let pkce = try pkceProvider.generatePKCE()
        currentPKCE = pkce

        var components = URLComponents(
            url: config.authorizationEndpoint,
            resolvingAgainstBaseURL: false
        )!
        var query: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(
                name: "redirect_uri",
                value: config.redirectURI.absoluteString
            ),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "state", value: pkce.state),
        ]

        if !config.scopes.isEmpty {
            query.append(
                URLQueryItem(
                    name: "scope",
                    value: config.scopes.spotifyQueryValue
                )
            )
        }

        if config.showDialog {
            query.append(URLQueryItem(name: "show_dialog", value: "true"))
        }

        components.queryItems = query
        return components.url!
    }

    // MARK: - Callback handling

    /// Handle the authorization callback and exchange the code for tokens.
    ///
    /// Call this method when your app receives the redirect from Spotify.
    ///
    /// - Parameter url: The callback URL containing the authorization code.
    /// - Returns: The access and refresh tokens.
    /// - Throws: ``SpotifyAuthError`` if the callback is invalid or token exchange fails.
    public func handleCallback(_ url: URL) async throws -> SpotifyTokens {
        guard let components = componentsBuilder(url) else {
            throw SpotifyAuthError.missingCode
        }

        let items = components.queryItems ?? []

        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        guard let code = value("code") else {
            throw SpotifyAuthError.missingCode
        }
        guard let state = value("state") else {
            throw SpotifyAuthError.missingState
        }
        guard let pkce = currentPKCE, pkce.state == state else {
            throw SpotifyAuthError.stateMismatch
        }

        currentPKCE = nil

        let tokens = try await exchangeCodeForTokens(
            code: code,
            codeVerifier: pkce.verifier
        )
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
        var request = URLRequest(url: config.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: config.clientID),
        ]

        request.httpBody = SpotifyAuthHTTP.formURLEncodedBody(from: items)

        let (data, response) = try await httpClient.data(for: request)
        return try SpotifyAuthHTTP.decodeTokens(
            from: data,
            response: response,
            existingRefreshToken: refreshToken
        )
    }

    // MARK: - Private helpers

    private func exchangeCodeForTokens(code: String, codeVerifier: String)
        async throws -> SpotifyTokens
    {
        var request = URLRequest(url: config.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(
                name: "redirect_uri",
                value: config.redirectURI.absoluteString
            ),
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
        ]

        request.httpBody = SpotifyAuthHTTP.formURLEncodedBody(from: items)

        let (data, response) = try await httpClient.data(for: request)
        return try SpotifyAuthHTTP.decodeTokens(
            from: data,
            response: response,
            existingRefreshToken: nil
        )
    }

    #if DEBUG
        func __test_formURLEncodedBody(items: [URLQueryItem]) -> Data {
            SpotifyAuthHTTP.formURLEncodedBody(from: items)
        }
    #endif
}

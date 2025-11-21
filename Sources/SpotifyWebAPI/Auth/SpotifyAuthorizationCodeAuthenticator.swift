import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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
        tokenStore: TokenStore = FileTokenStore(),
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

    public func makeAuthorizationURL() throws -> URL {
        let state = Self.generateState()
        currentState = state

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
            URLQueryItem(name: "state", value: state),
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
        guard let expected = currentState, expected == state else {
            throw SpotifyAuthError.stateMismatch
        }

        currentState = nil

        let tokens = try await exchangeCodeForTokens(code: code)
        try await persist(tokens)
        return tokens
    }

    // MARK: - Refresh

    public func refreshAccessToken(refreshToken: String) async throws
        -> SpotifyTokens
    {
        guard let clientSecret = config.clientSecret else {
            throw SpotifyAuthError.unexpectedResponse
        }

        var request = URLRequest(url: config.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        
        // Use Basic Authentication as per Spotify documentation
        let credentials = "\(config.clientID):\(clientSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue(
                "Basic \(base64Credentials)",
                forHTTPHeaderField: "Authorization"
            )
        }

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
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

    private func exchangeCodeForTokens(code: String) async throws
        -> SpotifyTokens
    {
        guard let clientSecret = config.clientSecret else {
            throw SpotifyAuthError.unexpectedResponse
        }

        var request = URLRequest(url: config.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        
        // Use Basic Authentication as per Spotify documentation
        let credentials = "\(config.clientID):\(clientSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue(
                "Basic \(base64Credentials)",
                forHTTPHeaderField: "Authorization"
            )
        }

        let items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(
                name: "redirect_uri",
                value: config.redirectURI.absoluteString
            ),
        ]

        request.httpBody = SpotifyAuthHTTP.formURLEncodedBody(from: items)

        let (data, response) = try await httpClient.data(for: request)
        return try SpotifyAuthHTTP.decodeTokens(
            from: data,
            response: response,
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

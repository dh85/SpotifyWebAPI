import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public actor SpotifyClientCredentialsAuthenticator {
    private let config: SpotifyAuthConfig
    private let httpClient: HTTPClient
    private let tokenStore: TokenStore?
    private var cachedTokens: SpotifyTokens?

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

    /// This is the method updated from suggestion #1 to fix the 401 retry bug.
    public func appAccessToken(invalidatingPrevious: Bool = false) async throws -> SpotifyTokens {
        // 1. Return from cache if valid and not being invalidated
        if let cachedTokens, !cachedTokens.isExpired, !invalidatingPrevious {
            return cachedTokens
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
        let fresh = try await requestNewAccessToken()
        if let tokenStore {
            try await tokenStore.save(fresh)
        }
        cachedTokens = fresh
        return fresh
    }

    // MARK: - Internal request/decoding
    private func requestNewAccessToken() async throws -> SpotifyTokens {
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

        var items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
        ]
        if !config.scopes.isEmpty {
            items.append(
                URLQueryItem(
                    name: "scope",
                    value: config.scopes.spotifyQueryValue
                )
            )
        }

        request.httpBody = SpotifyAuthHTTP.formURLEncodedBody(from: items)
        let (data, response) = try await httpClient.data(for: request)
        let tokens = try SpotifyAuthHTTP.decodeTokens(
            from: data,
            response: response,
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

    #if DEBUG
        nonisolated func __test_formURLEncodedBody(items: [URLQueryItem]) -> Data {
            SpotifyAuthHTTP.formURLEncodedBody(from: items)
        }
    #endif
}

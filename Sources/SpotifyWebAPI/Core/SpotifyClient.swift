import Foundation

public actor SpotifyClient<Capability: Sendable> {
    let httpClient: HTTPClient
    private let backend: TokenGrantAuthenticator

    init(
        backend: TokenGrantAuthenticator,
        httpClient: HTTPClient = URLSessionHTTPClient()
    ) {
        self.backend = backend
        self.httpClient = httpClient
    }

    // MARK: - Internal auth helper

    /// Helper to get the string token from the backend.
    /// - Parameter invalidatingPrevious: If true, force a refresh/invalidate cache.
    func accessToken(invalidatingPrevious: Bool = false) async throws -> String
    {
        // Pass the flag through to the backend
        let tokens = try await backend.accessToken(
            invalidatingPrevious: invalidatingPrevious
        )
        return tokens.accessToken
    }
}

// Sugar so you don't have to write the generic everywhere.
public typealias UserSpotifyClient = SpotifyClient<UserAuthCapability>
public typealias AppSpotifyClient = SpotifyClient<AppOnlyAuthCapability>

extension SpotifyClient where Capability == UserAuthCapability {

    /// PKCE client for public/mobile apps.
    public static func pkce(
        clientID: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false,
        tokenStore: TokenStore = FileTokenStore(),
        httpClient: HTTPClient = URLSessionHTTPClient(),
        pkceProvider: PKCEProvider = DefaultPKCEProvider()
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

        return SpotifyClient(backend: backend, httpClient: httpClient)
    }

    /// Authorization Code + client secret for confidential apps.
    public static func authorizationCode(
        clientID: String,
        clientSecret: String,
        redirectURI: URL,
        scopes: Set<SpotifyScope>,
        showDialog: Bool = false,
        tokenStore: TokenStore = FileTokenStore(),
        httpClient: HTTPClient = URLSessionHTTPClient()
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

        return SpotifyClient(backend: backend, httpClient: httpClient)
    }
}

extension SpotifyClient where Capability == AppOnlyAuthCapability {

    /// Client Credentials for app-only access to public data.
    public static func clientCredentials(
        clientID: String,
        clientSecret: String,
        scopes: Set<SpotifyScope> = [],
        httpClient: HTTPClient = URLSessionHTTPClient(),
        tokenStore: TokenStore? = nil
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

        return SpotifyClient(backend: backend, httpClient: httpClient)
    }
}

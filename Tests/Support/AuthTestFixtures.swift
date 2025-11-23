import Foundation

@testable import SpotifyWebAPI

enum AuthTestFixtures {

    static func tokenResponse(
        accessToken: String = "ACCESS",
        refreshToken: String? = "REFRESH",
        expiresIn: Int = 3600,
        scope: String? = "user-read-email playlist-read-private",
        tokenType: String = "Bearer"
    ) -> Data {
        var payload: [String: Any] = [
            "access_token": accessToken,
            "token_type": tokenType,
            "expires_in": expiresIn,
        ]

        if let scope {
            payload["scope"] = scope
        }
        if let refreshToken {
            payload["refresh_token"] = refreshToken
        }

        return try! JSONSerialization.data(withJSONObject: payload, options: [])
    }

    static func authCodeConfig(
        scopes: Set<SpotifyScope> = [.userReadEmail, .playlistReadPrivate],
        showDialog: Bool = true
    ) -> SpotifyAuthConfig {
        .authorizationCode(
            clientID: "TEST_CLIENT_ID",
            clientSecret: "TEST_SECRET",
            redirectURI: URL(string: "myapp://callback")!,
            scopes: scopes,
            showDialog: showDialog
        )
    }

    static func pkceConfig(
        scopes: Set<SpotifyScope> = [.userReadEmail, .playlistReadPrivate],
        showDialog: Bool = true
    ) -> SpotifyAuthConfig {
        .pkce(
            clientID: "TEST_CLIENT_ID",
            redirectURI: URL(string: "myapp://callback")!,
            scopes: scopes,
            showDialog: showDialog
        )
    }

    static func clientCredentialsConfig(
        scopes: Set<SpotifyScope> = []
    ) -> SpotifyAuthConfig {
        .clientCredentials(
            clientID: "TEST_CLIENT_ID",
            clientSecret: "TEST_SECRET",
            scopes: scopes
        )
    }

    static func pkcePair(
        verifier: String = "VERIFIER",
        challenge: String = "CHALLENGE",
        state: String = "STATE123"
    ) -> PKCEPair {
        PKCEPair(verifier: verifier, challenge: challenge, state: state)
    }
}

struct AuthenticatorTestHarness {
    let httpClient: SimpleMockHTTPClient
    let tokenStore: InMemoryTokenStore

    init(
        response: SimpleMockHTTPClient.Response = .success(
            data: Data(),
            statusCode: 200
        ),
        tokens: SpotifyTokens? = nil
    ) {
        self.httpClient = SimpleMockHTTPClient(response: response)
        self.tokenStore = InMemoryTokenStore(tokens: tokens)
    }

    func makeAuthorizationCodeAuthenticator(
        config: SpotifyAuthConfig = AuthTestFixtures.authCodeConfig()
    ) -> SpotifyAuthorizationCodeAuthenticator {
        SpotifyAuthorizationCodeAuthenticator(
            config: config,
            httpClient: httpClient,
            tokenStore: tokenStore
        )
    }

    func makePKCEAuthenticator(
        config: SpotifyAuthConfig = AuthTestFixtures.pkceConfig(),
        pkceProvider: PKCEProvider = FixedPKCEProvider(pair: AuthTestFixtures.pkcePair())
    ) -> SpotifyPKCEAuthenticator {
        SpotifyPKCEAuthenticator(
            config: config,
            pkceProvider: pkceProvider,
            httpClient: httpClient,
            tokenStore: tokenStore
        )
    }

    func makeClientCredentialsAuthenticator(
        config: SpotifyAuthConfig = AuthTestFixtures.clientCredentialsConfig()
    ) -> SpotifyClientCredentialsAuthenticator {
        SpotifyClientCredentialsAuthenticator(
            config: config,
            httpClient: httpClient,
            tokenStore: tokenStore
        )
    }
}

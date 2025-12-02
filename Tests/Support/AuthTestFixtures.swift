import Foundation
import Testing

@testable import SpotifyKit

enum AuthTestFixtures {

    // MARK: - Token Response Builders

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

    // MARK: - Token Fixtures

    /// Creates sample SpotifyTokens for testing.
    ///
    /// This shared helper eliminates duplication across token store tests.
    static func sampleTokens(
        accessToken: String = "ACCESS",
        refreshToken: String? = "REFRESH",
        expiresIn: TimeInterval = 3600,
        scope: String? = "user-read-email",
        tokenType: String = "Bearer"
    ) -> SpotifyTokens {
        SpotifyTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            scope: scope,
            tokenType: tokenType
        )
    }

    /// Asserts that two tokens are equal with tolerance for expiration date differences.
    ///
    /// Useful for comparing tokens loaded from storage where minor timing differences are expected.
    static func assertTokensEqual(
        _ actual: SpotifyTokens?,
        _ expected: SpotifyTokens,
        dateToleranceSeconds: TimeInterval = 1.0,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard let actual else {
            Issue.record(
                "Expected non-nil tokens",
                sourceLocation: sourceLocation
            )
            return
        }
        #expect(actual.accessToken == expected.accessToken)
        #expect(actual.refreshToken == expected.refreshToken)
        #expect(actual.scope == expected.scope)
        #expect(actual.tokenType == expected.tokenType)
        let delta = abs(actual.expiresAt.timeIntervalSince(expected.expiresAt))
        #expect(
            delta < dateToleranceSeconds,
            "Expiration time differs by \(delta) seconds"
        )
    }

    // MARK: - Auth Config Builders

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

    // MARK: - URL Helpers

    /// Extracts a query parameter value from a URL.
    ///
    /// Simplifies repeated pattern of parsing URL components and finding query items.
    static func queryValue(from url: URL, name: String) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }

    /// Builds a callback URL with specified query parameters.
    ///
    /// Provides type-safe construction of OAuth callback URLs for tests.
    static func callbackURL(
        code: String? = nil,
        state: String? = nil,
        error: String? = nil,
        baseURL: String = "myapp://callback"
    ) -> URL {
        var components = URLComponents(string: baseURL)!
        var items: [URLQueryItem] = []
        if let code { items.append(URLQueryItem(name: "code", value: code)) }
        if let state { items.append(URLQueryItem(name: "state", value: state)) }
        if let error { items.append(URLQueryItem(name: "error", value: error)) }
        components.queryItems = items.isEmpty ? nil : items
        return components.url!
    }

    // MARK: - PKCE Helpers

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

    /// Convenience factory for creating a test harness.
    ///
    /// Provides consistent harness creation across authenticator tests.
    static func makeHarness(
        response: SimpleMockHTTPClient.Response = .success(
            data: Data(),
            statusCode: 200
        ),
        tokens: SpotifyTokens? = nil
    ) -> AuthenticatorTestHarness {
        AuthenticatorTestHarness(response: response, tokens: tokens)
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

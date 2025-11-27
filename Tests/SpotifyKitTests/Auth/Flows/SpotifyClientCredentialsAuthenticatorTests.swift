import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SpotifyClientCredentialsAuthenticatorTests {

    // MARK: - Helpers

    private func makeConfig(
        scopes: Set<SpotifyScope> = []
    ) -> SpotifyAuthConfig {
        AuthTestFixtures.clientCredentialsConfig(scopes: scopes)
    }

    private func makeTokenJSON(
        accessToken: String,
        expiresIn: Int = 3600,
        scope: String? = nil,
        tokenType: String = "Bearer"
    ) -> Data {
        AuthTestFixtures.tokenResponse(
            accessToken: accessToken,
            refreshToken: nil,
            expiresIn: expiresIn,
            scope: scope,
            tokenType: tokenType
        )
    }

    // MARK: - appAccessToken happy paths

    @Test
    func appAccessToken_requestsNewTokenWhenNoCacheOrStore() async throws {
        let json = makeTokenJSON(
            accessToken: "ACCESS_1",
            expiresIn: 3600,
            scope: "some-scope"
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: nil
        )

        let tokens = try await auth.appAccessToken()
        #expect(tokens.accessToken == "ACCESS_1")
        #expect(tokens.refreshToken == nil)
        #expect(tokens.scope == "some-scope")
        #expect(tokens.tokenType == "Bearer")
    }

    @Test
    func appAccessToken_reusesCachedNonExpiredToken() async throws {
        let json = makeTokenJSON(
            accessToken: "ACCESS_1",
            expiresIn: 3600
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: nil
        )

        let first = try await auth.appAccessToken()
        let second = try await auth.appAccessToken()

        #expect(first.accessToken == "ACCESS_1")
        #expect(second.accessToken == "ACCESS_1")
    }

    @Test
    func appAccessToken_loadsFromStoreWhenNotExpired() async throws {
        let stored = SpotifyTokens(
            accessToken: "STORED_ACCESS",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let harness = AuthenticatorTestHarness.makeHarness(tokens: stored)
        let auth = harness.makeClientCredentialsAuthenticator()

        let token = try await auth.appAccessToken()
        #expect(token.accessToken == "STORED_ACCESS")
    }

    @Test
    func appAccessToken_refreshesWhenStoreTokenExpiredAndPersists() async throws {
        let expired = SpotifyTokens(
            accessToken: "OLD",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(-3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let json = makeTokenJSON(accessToken: "NEW_ACCESS", expiresIn: 3600)
        let harness = AuthenticatorTestHarness.makeHarness(
            response: .success(data: json, statusCode: 200),
            tokens: expired
        )
        let auth = harness.makeClientCredentialsAuthenticator()

        let token = try await auth.appAccessToken()
        #expect(token.accessToken == "NEW_ACCESS")

        // It should have persisted back
        let persisted = try await harness.tokenStore.load()
        #expect(persisted?.accessToken == "NEW_ACCESS")
    }

    // MARK: - Scopes & body format

    @Test
    func appAccessToken_includesScopesInBody() async throws {
        let json = makeTokenJSON(accessToken: "ACCESS_SCOPED", scope: "a b")
        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(scopes: [.userReadEmail, .playlistReadPrivate]),
            httpClient: http,
            tokenStore: nil
        )

        _ = try await auth.appAccessToken()

        #expect(http.recordedRequests.count == 1)
        let request = http.recordedRequests[0]

        #expect(request.httpMethod == "POST")
        #expect(
            request.value(forHTTPHeaderField: "Content-Type")
                == "application/x-www-form-urlencoded"
        )

        // Check Authorization header (Basic Auth)
        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
            #expect(authHeader.hasPrefix("Basic "))
            let base64 = String(authHeader.dropFirst("Basic ".count))
            if let decoded = Data(base64Encoded: base64),
                let credentials = String(data: decoded, encoding: .utf8)
            {
                #expect(credentials == "TEST_CLIENT_ID:TEST_SECRET")
            } else {
                Issue.record("Failed to decode Basic Auth credentials")
            }
        } else {
            Issue.record("Expected Authorization header")
        }

        if let bodyData = request.httpBody,
            let body = String(data: bodyData, encoding: .utf8)
        {
            #expect(body.contains("grant_type=client_credentials"))
            #expect(!body.contains("client_id="))
            #expect(!body.contains("client_secret="))

            // The scopes ordering depends on Set ordering; just assert both terms exist.
            #expect(body.contains("scope="))
            #expect(
                body.contains("user-read-email")
                    || body.contains("playlist-read-private")
            )
        } else {
            Issue.record("Expected non-nil UTF-8 request body")
        }
    }

    @Test
    func formURLEncodedBody_emptyItemsProducesEmptyString() async throws {
        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: nil
        )

        let data = __test_formURLEncodedBody(items: [])
        let string = String(data: data, encoding: .utf8)
        #expect(string == "")
    }

    // MARK: - loadPersistedTokens Tests

    @Test
    func loadPersistedTokens_returnsCachedTokens() async throws {
        let json = makeTokenJSON(accessToken: "CACHED", expiresIn: 3600)
        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: nil
        )

        // First call to populate cache
        _ = try await auth.appAccessToken()

        // loadPersistedTokens should return cached
        let loaded = try await auth.loadPersistedTokens()
        #expect(loaded?.accessToken == "CACHED")
    }

    @Test
    func loadPersistedTokens_returnsNilWhenNoStore() async throws {
        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: nil
        )

        let loaded = try await auth.loadPersistedTokens()
        #expect(loaded == nil)
    }

    @Test
    func loadPersistedTokens_loadsFromStoreAndCaches() async throws {
        let stored = SpotifyTokens(
            accessToken: "STORED",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let harness = AuthenticatorTestHarness.makeHarness(tokens: stored)
        let auth = harness.makeClientCredentialsAuthenticator()

        let loaded = try await auth.loadPersistedTokens()
        #expect(loaded?.accessToken == "STORED")

        // Second call should return cached
        let cached = try await auth.loadPersistedTokens()
        #expect(cached?.accessToken == "STORED")
    }

    @Test
    func requestNewAccessToken_throwsWhenNoClientSecret() async throws {
        // Use PKCE config which has no clientSecret
        let configWithoutSecret = SpotifyAuthConfig.pkce(
            clientID: "TEST_CLIENT_ID",
            redirectURI: URL(string: "test://callback")!,
            scopes: []
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: configWithoutSecret,
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: nil
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await auth.appAccessToken()
        }
    }

    // MARK: - Error paths

    @Test
    func appAccessToken_unexpectedResponseWhenNonHTTPURLResponse() async {
        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: NonHTTPResponseMockHTTPClient(),
            tokenStore: nil
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await auth.appAccessToken()
        }
    }

    @Test
    func appAccessToken_httpErrorWithUTF8Body() async {
        let http = StatusMockHTTPClient(statusCode: 400, body: "bad request")

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: nil
        )

        await #expect(
            throws: SpotifyAuthError.httpError(
                statusCode: 400,
                body: "bad request"
            )
        ) {
            _ = try await auth.appAccessToken()
        }
    }

    @Test
    func appAccessToken_httpErrorWithNonUTF8BodyUsesFallbackString() async {
        let invalidData = Data([0xFF, 0xFF, 0xFF])

        let http = BinaryBodyMockHTTPClient(
            statusCode: 400,
            data: invalidData
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: nil
        )

        await #expect(
            throws: SpotifyAuthError.httpError(
                statusCode: 400,
                body: "<non-utf8 body>"
            )
        ) {
            _ = try await auth.appAccessToken()
        }
    }
}

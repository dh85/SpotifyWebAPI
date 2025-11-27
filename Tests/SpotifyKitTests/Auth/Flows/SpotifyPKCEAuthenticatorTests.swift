import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SpotifyPKCEAuthenticatorTests {

    // MARK: - Shared helpers

    private func makeConfig() -> SpotifyAuthConfig {
        AuthTestFixtures.pkceConfig()
    }

    // MARK: - SpotifyAuthError Equatable

    @Test
    func spotifyAuthErrorEquatableCoverage() {
        #expect(SpotifyAuthError.missingCode == .missingCode)
        #expect(SpotifyAuthError.missingCode != .missingState)

        let e1 = SpotifyAuthError.httpError(statusCode: 400, body: "oops")
        let e2 = SpotifyAuthError.httpError(statusCode: 400, body: "oops")
        let e3 = SpotifyAuthError.httpError(statusCode: 500, body: "oops")

        #expect(e1 == e2)
        #expect(e1 != e3)
    }

    // MARK: - makeAuthorizationURL

    @Test
    func makeAuthorizationURL_buildsCorrectQuery() async throws {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let harness = AuthenticatorTestHarness.makeHarness()
        let auth = harness.makePKCEAuthenticator(
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE)
        )

        let url = try await auth.makeAuthorizationURL()

        #expect(AuthTestFixtures.queryValue(from: url, name: "client_id") == "TEST_CLIENT_ID")
        #expect(AuthTestFixtures.queryValue(from: url, name: "response_type") == "code")
        #expect(AuthTestFixtures.queryValue(from: url, name: "redirect_uri") == "myapp://callback")
        #expect(AuthTestFixtures.queryValue(from: url, name: "code_challenge_method") == "S256")
        #expect(AuthTestFixtures.queryValue(from: url, name: "code_challenge") == "CHALLENGE")
        #expect(AuthTestFixtures.queryValue(from: url, name: "state") == "STATE123")
        #expect(AuthTestFixtures.queryValue(from: url, name: "scope")!.contains("user-read-email"))
        #expect(
            AuthTestFixtures.queryValue(from: url, name: "scope")!.contains("playlist-read-private")
        )
        #expect(AuthTestFixtures.queryValue(from: url, name: "show_dialog") == "true")
    }

    // MARK: - handleCallback success + error paths

    @Test
    func handleCallback_exchangesCodeForTokensAndPersists() async throws {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let tokenJSON = AuthTestFixtures.tokenResponse(
            accessToken: "ACCESS123",
            refreshToken: "REFRESH123"
        )

        let harness = AuthenticatorTestHarness.makeHarness(
            response: .success(data: tokenJSON, statusCode: 200)
        )
        let auth = harness.makePKCEAuthenticator(
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE)
        )

        _ = try await auth.makeAuthorizationURL()

        let callback = AuthTestFixtures.callbackURL(code: "AUTH_CODE", state: "STATE123")

        let tokens = try await auth.handleCallback(callback)

        #expect(tokens.accessToken == "ACCESS123")
        #expect(tokens.refreshToken == "REFRESH123")
        #expect(tokens.tokenType == "Bearer")
        #expect(tokens.scope == "user-read-email playlist-read-private")
        #expect(tokens.isExpired == false)

        let stored = try await harness.tokenStore.load()
        #expect(stored == tokens)

        #expect(harness.httpClient.recordedRequests.count == 1)
    }

    @Test
    func handleCallback_missingCodeFromComponentsBuilderNil() async {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let url = URL(string: "myapp://callback?code=AUTH&state=STATE123")!
        let harness = AuthenticatorTestHarness.makeHarness()
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE),
            httpClient: harness.httpClient,
            tokenStore: harness.tokenStore,
            componentsBuilder: { _ in nil }
        )

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(url)
        }
    }

    @Test
    func handleCallback_noQueryItemsTriggersNilQueryItemsBranch() async {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let harness = AuthenticatorTestHarness.makeHarness()
        let auth = harness.makePKCEAuthenticator(
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE)
        )

        _ = try! await auth.makeAuthorizationURL()

        let url = AuthTestFixtures.callbackURL()

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(url)
        }
    }

    @Test
    func handleCallback_missingCodeThrows() async {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let harness = AuthenticatorTestHarness.makeHarness()
        let auth = harness.makePKCEAuthenticator(
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE)
        )

        _ = try! await auth.makeAuthorizationURL()

        let url = AuthTestFixtures.callbackURL(state: "STATE123")

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(url)
        }
    }

    @Test
    func handleCallback_missingStateThrows() async {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let mockHTTP = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )

        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE),
            httpClient: mockHTTP,
            tokenStore: InMemoryTokenStore()
        )

        _ = try! await auth.makeAuthorizationURL()

        let url = AuthTestFixtures.callbackURL(code: "AUTH_CODE")

        await #expect(throws: SpotifyAuthError.missingState) {
            _ = try await auth.handleCallback(url)
        }
    }

    @Test
    func handleCallback_stateMismatchThrows() async {
        let fixedPKCE = PKCEPair(
            verifier: "VERIFIER",
            challenge: "CHALLENGE",
            state: "STATE123"
        )

        let mockHTTP = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )

        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            pkceProvider: FixedPKCEProvider(pair: fixedPKCE),
            httpClient: mockHTTP,
            tokenStore: InMemoryTokenStore()
        )

        _ = try! await auth.makeAuthorizationURL()

        let badURL = AuthTestFixtures.callbackURL(code: "AUTH_CODE", state: "OTHER")

        await #expect(throws: SpotifyAuthError.stateMismatch) {
            _ = try await auth.handleCallback(badURL)
        }
    }

    // MARK: - formURLEncodedBody via debug helper

    @Test
    func formURLEncodedBody_nilPercentEncodedQueryWhenItemsEmpty() async throws {
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            tokenStore: InMemoryTokenStore()
        )

        let data = __test_formURLEncodedBody(items: [])
        let string = String(data: data, encoding: .utf8)

        #expect(string == "")
    }

    // MARK: - loadPersistedTokens

    @Test
    func loadPersistedTokens_usesCacheOnSecondCall() async throws {
        let tokens = SpotifyTokens(
            accessToken: "ACCESS",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let store = InMemoryTokenStore(tokens: tokens)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            tokenStore: store
        )

        let first = try await auth.loadPersistedTokens()
        let second = try await auth.loadPersistedTokens()

        #expect(first == tokens)
        #expect(second == tokens)
    }

    // MARK: - refreshAccessTokenIfNeeded branches

    @Test
    func refreshAccessTokenIfNeeded_usesCachedNotExpired() async throws {
        let tokens = SpotifyTokens(
            accessToken: "ACCESS",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let store = InMemoryTokenStore(tokens: tokens)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            tokenStore: store
        )

        _ = try await auth.loadPersistedTokens()

        let result = try await auth.refreshAccessTokenIfNeeded()
        #expect(result == tokens)
    }

    @Test
    func refreshAccessTokenIfNeeded_cachedExpiredWithRefresh() async throws {
        let expired = SpotifyTokens(
            accessToken: "OLD",
            refreshToken: "REFRESH_OLD",
            expiresAt: Date().addingTimeInterval(-3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let newJSON = AuthTestFixtures.tokenResponse(
            accessToken: "NEW_ACCESS",
            refreshToken: nil
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: newJSON, statusCode: 200)
        )

        let store = InMemoryTokenStore(tokens: expired)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        _ = try await auth.loadPersistedTokens()

        let refreshed = try await auth.refreshAccessTokenIfNeeded()

        #expect(refreshed.accessToken == "NEW_ACCESS")
        #expect(refreshed.refreshToken == "REFRESH_OLD")
    }

    @Test
    func refreshAccessTokenIfNeeded_loadsFromStoreNotExpired() async throws {
        let tokens = SpotifyTokens(
            accessToken: "ACCESS_STORE",
            refreshToken: "REFRESH_STORE",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let store = InMemoryTokenStore(tokens: tokens)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            tokenStore: store
        )

        let result = try await auth.refreshAccessTokenIfNeeded()
        #expect(result == tokens)
    }

    @Test
    func refreshAccessTokenIfNeeded_storeExpiredWithRefresh() async throws {
        let expired = SpotifyTokens(
            accessToken: "OLD_STORE",
            refreshToken: "REFRESH_STORE",
            expiresAt: Date().addingTimeInterval(-3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let newJSON = AuthTestFixtures.tokenResponse(
            accessToken: "NEW_FROM_REFRESH",
            refreshToken: "REFRESH_NEW"
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: newJSON, statusCode: 200)
        )

        let store = InMemoryTokenStore(tokens: expired)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        let refreshed = try await auth.refreshAccessTokenIfNeeded()

        #expect(refreshed.accessToken == "NEW_FROM_REFRESH")
        #expect(refreshed.refreshToken == "REFRESH_NEW")
    }

    @Test
    func refreshAccessTokenIfNeeded_missingRefreshTokenThrows() async {
        let store = InMemoryTokenStore(tokens: nil)
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            tokenStore: store
        )

        await #expect(throws: SpotifyAuthError.missingRefreshToken) {
            _ = try await auth.refreshAccessTokenIfNeeded()
        }
    }

    // MARK: - refreshAccessToken direct

    @Test
    func
        refreshAccessToken_successUsesExistingRefreshTokenWhenMissingInResponse()
        async throws
    {
        let json = AuthTestFixtures.tokenResponse(
            accessToken: "NEW_ACCESS",
            refreshToken: nil
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: InMemoryTokenStore()
        )

        let tokens = try await auth.refreshAccessToken(refreshToken: "REF_OLD")

        #expect(tokens.accessToken == "NEW_ACCESS")
        #expect(tokens.refreshToken == "REF_OLD")
    }

    @Test
    func refreshAccessToken_unexpectedResponseWhenNonHTTPURLResponse() async {
        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: NonHTTPResponseMockHTTPClient(),
            tokenStore: InMemoryTokenStore()
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await auth.refreshAccessToken(refreshToken: "REF")
        }
    }

    @Test
    func refreshAccessToken_httpErrorWithUTF8Body() async {
        let http = StatusMockHTTPClient(statusCode: 400, body: "bad request")

        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: InMemoryTokenStore()
        )

        await #expect(
            throws: SpotifyAuthError.httpError(
                statusCode: 400,
                body: "bad request"
            )
        ) {
            _ = try await auth.refreshAccessToken(refreshToken: "REF")
        }
    }

    @Test
    func refreshAccessToken_httpErrorWithNonUTF8BodyUsesFallbackString() async {
        let invalidData = Data([0xFF, 0xFF, 0xFF])

        let http = BinaryBodyMockHTTPClient(
            statusCode: 400,
            data: invalidData
        )

        let auth = SpotifyPKCEAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: InMemoryTokenStore()
        )

        await #expect(
            throws: SpotifyAuthError.httpError(
                statusCode: 400,
                body: "<non-utf8 body>"
            )
        ) {
            _ = try await auth.refreshAccessToken(refreshToken: "REF")
        }
    }
}

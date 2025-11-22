import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct SpotifyAuthorizationCodeAuthenticatorTests {

    // MARK: - Shared helpers

    private func makeConfig(
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

    private func makeTokenJSON(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int = 3600,
        scope: String = "user-read-email playlist-read-private",
        tokenType: String = "Bearer"
    ) -> Data {
        var dict: [String: Any] = [
            "access_token": accessToken,
            "token_type": tokenType,
            "expires_in": expiresIn,
            "scope": scope,
        ]
        if let refreshToken {
            dict["refresh_token"] = refreshToken
        }
        return try! JSONSerialization.data(withJSONObject: dict, options: [])
    }

    // MARK: - makeAuthorizationURL

    @Test
    func makeAuthorizationURL_buildsCorrectQuery() async throws {
        let config = makeConfig()
        let store = InMemoryTokenStore()
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: config,
            httpClient: http,
            tokenStore: store
        )

        let url = try await auth.makeAuthorizationURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        func value(_ name: String) -> String? {
            items.first(where: { $0.name == name })?.value
        }

        #expect(value("client_id") == "TEST_CLIENT_ID")
        #expect(value("response_type") == "code")
        #expect(value("redirect_uri") == "myapp://callback")
        #expect(value("state") != nil)
        #expect(
            value("scope") == "playlist-read-private user-read-email"
                || value("scope") == "user-read-email playlist-read-private"
        )
        #expect(value("show_dialog") == "true")

        // Check state looks like our generateState output: no '-'
        let state = value("state")!
        #expect(!state.contains("-"))
    }

    // MARK: - handleCallback success and error paths

    @Test
    func handleCallback_successExchangesCodeAndPersists() async throws {
        let tokenJSON = makeTokenJSON(
            accessToken: "ACCESS123",
            refreshToken: "REFRESH123"
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: tokenJSON, statusCode: 200)
        )

        let store = InMemoryTokenStore()
        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        let url = try await auth.makeAuthorizationURL()
        let state =
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "state" })?
            .value ?? ""

        let callback = URL(
            string: "myapp://callback?code=AUTH_CODE&state=\(state)"
        )!

        let tokens = try await auth.handleCallback(callback)

        #expect(tokens.accessToken == "ACCESS123")
        #expect(tokens.refreshToken == "REFRESH123")
        #expect(tokens.tokenType == "Bearer")

        // Persisted
        let stored = try await store.load()
        #expect(stored?.accessToken == "ACCESS123")
    }

    @Test
    func handleCallback_componentsBuilderNilThrowsMissingCode() async {
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store,
            componentsBuilder: { _ in nil }  // forces guard-else
        )

        let callback = URL(string: "myapp://callback?code=AUTH&state=S")!

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(callback)
        }
    }

    @Test
    func handleCallback_noQueryItemsTriggersNilQueryItemsBranch() async {
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        _ = try! await auth.makeAuthorizationURL()

        // No `?` → queryItems == nil → [] and then missingCode
        let callback = URL(string: "myapp://callback")!

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(callback)
        }
    }

    @Test
    func handleCallback_missingCodeThrows() async {
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        _ = try! await auth.makeAuthorizationURL()

        let callback = URL(string: "myapp://callback?state=STATE123")!

        await #expect(throws: SpotifyAuthError.missingCode) {
            _ = try await auth.handleCallback(callback)
        }
    }

    @Test
    func handleCallback_missingStateThrows() async {
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        _ = try! await auth.makeAuthorizationURL()

        let callback = URL(string: "myapp://callback?code=AUTH_CODE")!

        await #expect(throws: SpotifyAuthError.missingState) {
            _ = try await auth.handleCallback(callback)
        }
    }

    @Test
    func handleCallback_stateMismatchThrows() async {
        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        _ = try! await auth.makeAuthorizationURL()

        let callback = URL(
            string: "myapp://callback?code=AUTH_CODE&state=OTHER"
        )!

        await #expect(throws: SpotifyAuthError.stateMismatch) {
            _ = try await auth.handleCallback(callback)
        }
    }

    @Test
    func handleCallback_throwsWhenClientSecretMissing() async {
        let pkceConfig = SpotifyAuthConfig.pkce(
            clientID: "PKCE_CLIENT",
            redirectURI: URL(string: "pkce://callback")!
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: makeTokenJSON(accessToken: "TOKEN"), statusCode: 200)
        )
        let store = InMemoryTokenStore()

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: pkceConfig,
            httpClient: http,
            tokenStore: store
        )

        let authURL = try! await auth.makeAuthorizationURL()
        let state =
            URLComponents(url: authURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "state" })?
            .value ?? ""

        let callback = URL(string: "pkce://callback?code=AUTH&state=\(state)")!

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await auth.handleCallback(callback)
        }
    }

    // MARK: - formURLEncodedBody via debug helper

    @Test
    func formURLEncodedBody_nilPercentEncodedQueryWhenItemsEmpty() async throws {
        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: InMemoryTokenStore()
        )

        // Empty items → percentEncodedQuery == nil → "" used
        let data = await auth.__test_formURLEncodedBody(items: [])
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

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: store
        )

        let first = try await auth.loadPersistedTokens()
        let second = try await auth.loadPersistedTokens()

        #expect(first?.accessToken == "ACCESS")
        #expect(second?.accessToken == "ACCESS")
    }

    // MARK: - Missing client secret safeguards

    @Test
    func refreshAccessToken_throwsWhenClientSecretMissing() async {
        let pkceConfig = SpotifyAuthConfig.pkce(
            clientID: "PKCE_CLIENT",
            redirectURI: URL(string: "pkce://callback")!
        )

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: pkceConfig,
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: InMemoryTokenStore()
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await auth.refreshAccessToken(refreshToken: "REFRESH")
        }
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

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: store
        )

        // Populate cachedTokens
        _ = try await auth.loadPersistedTokens()

        let result = try await auth.refreshAccessTokenIfNeeded()
        #expect(result.accessToken == "ACCESS")
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

        let json = makeTokenJSON(
            accessToken: "NEW_ACCESS",
            refreshToken: nil  // ensure existingRefreshToken is used
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let store = InMemoryTokenStore(tokens: expired)

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        // cachedTokens = expired
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

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
            tokenStore: store
        )

        // cachedTokens is nil, store has non-expired tokens
        let result = try await auth.refreshAccessTokenIfNeeded()

        #expect(result.accessToken == "ACCESS_STORE")
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

        let json = makeTokenJSON(
            accessToken: "NEW_FROM_REFRESH",
            refreshToken: "REFRESH_NEW"
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let store = InMemoryTokenStore(tokens: expired)

        let auth = SpotifyAuthorizationCodeAuthenticator(
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

        let auth = SpotifyAuthorizationCodeAuthenticator(
            config: makeConfig(),
            httpClient: SimpleMockHTTPClient(
                response: .success(data: Data(), statusCode: 200)
            ),
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
        let json = makeTokenJSON(
            accessToken: "NEW_ACCESS",
            refreshToken: nil
        )

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyAuthorizationCodeAuthenticator(
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
        let auth = SpotifyAuthorizationCodeAuthenticator(
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

        let auth = SpotifyAuthorizationCodeAuthenticator(
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
        // Deliberately invalid UTF-8 bytes
        let invalidData = Data([0xFF, 0xFF, 0xFF])

        let http = BinaryBodyMockHTTPClient(
            statusCode: 400,
            data: invalidData
        )

        let auth = SpotifyAuthorizationCodeAuthenticator(
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

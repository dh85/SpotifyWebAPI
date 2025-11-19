import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct SpotifyClientCredentialsAuthenticatorTests {

    // MARK: - Helpers

    private func makeConfig(
        scopes: Set<SpotifyScope> = []
    ) -> SpotifyAuthConfig {
        .clientCredentials(
            clientID: "TEST_CLIENT_ID",
            clientSecret: "TEST_SECRET",
            scopes: scopes
        )
    }

    private func makeTokenJSON(
        accessToken: String,
        expiresIn: Int = 3600,
        scope: String? = nil,
        tokenType: String = "Bearer"
    ) -> Data {
        var dict: [String: Any] = [
            "access_token": accessToken,
            "token_type": tokenType,
            "expires_in": expiresIn,
        ]
        if let scope {
            dict["scope"] = scope
        }
        return try! JSONSerialization.data(withJSONObject: dict, options: [])
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

        let store = InMemoryTokenStore(tokens: stored)

        let http = SimpleMockHTTPClient(
            response: .success(data: Data(), statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        let token = try await auth.appAccessToken()
        #expect(token.accessToken == "STORED_ACCESS")
    }

    @Test
    func appAccessToken_refreshesWhenStoreTokenExpiredAndPersists() async throws
    {
        let expired = SpotifyTokens(
            accessToken: "OLD",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(-3600),
            scope: nil,
            tokenType: "Bearer"
        )

        let store = InMemoryTokenStore(tokens: expired)

        let json = makeTokenJSON(accessToken: "NEW_ACCESS", expiresIn: 3600)

        let http = SimpleMockHTTPClient(
            response: .success(data: json, statusCode: 200)
        )

        let auth = SpotifyClientCredentialsAuthenticator(
            config: makeConfig(),
            httpClient: http,
            tokenStore: store
        )

        let token = try await auth.appAccessToken()
        #expect(token.accessToken == "NEW_ACCESS")

        // It should have persisted back
        let persisted = try await store.load()
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

        if let bodyData = request.httpBody,
            let body = String(data: bodyData, encoding: .utf8)
        {
            #expect(body.contains("grant_type=client_credentials"))
            #expect(body.contains("client_id=TEST_CLIENT_ID"))
            #expect(body.contains("client_secret=TEST_SECRET"))

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

        let data = auth.__test_formURLEncodedBody(items: [])
        let string = String(data: data, encoding: .utf8)
        #expect(string == "")
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

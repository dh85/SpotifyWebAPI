#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyKit

    @Suite("Authenticator Combine Tests")
    @MainActor
    struct AuthenticatorCombineTests {

        @Test("PKCE handleCallbackPublisher emits tokens")
        func pkceHandleCallbackPublisherEmitsTokens() async throws {
            let responseData = AuthTestFixtures.tokenResponse(
                accessToken: "ACCESS",
                refreshToken: "REFRESH"
            )
            let harness = AuthenticatorTestHarness.makeHarness(
                response: .success(data: responseData, statusCode: 200)
            )

            let authenticator = harness.makePKCEAuthenticator()
            _ = try await authenticator.makeAuthorizationURL()
            let callback = AuthTestFixtures.callbackURL(
                code: "CODE123",
                state: AuthTestFixtures.pkcePair().state
            )

            let tokens = try await awaitFirstValue(
                authenticator.handleCallbackPublisher(callback)
            )

            #expect(tokens.accessToken == "ACCESS")
            let stored = try await harness.tokenStore.load()
            AuthTestFixtures.assertTokensEqual(stored, tokens)
        }

        @Test("Authorization Code refreshAccessTokenPublisher refreshes tokens")
        func authorizationCodeRefreshPublisherEmitsTokens() async throws {
            let responseData = AuthTestFixtures.tokenResponse(
                accessToken: "NEW_ACCESS",
                refreshToken: "NEW_REFRESH"
            )
            let harness = AuthenticatorTestHarness.makeHarness(
                response: .success(data: responseData, statusCode: 200)
            )

            let authenticator = harness.makeAuthorizationCodeAuthenticator()
            let tokens = try await awaitFirstValue(
                authenticator.refreshAccessTokenPublisher(refreshToken: "REFRESH")
            )

            #expect(tokens.accessToken == "NEW_ACCESS")
            #expect(tokens.refreshToken == "NEW_REFRESH")
        }

        @Test("Client Credentials appAccessTokenPublisher emits app tokens")
        func clientCredentialsAppAccessTokenPublisherEmitsTokens() async throws {
            let responseData = AuthTestFixtures.tokenResponse(
                accessToken: "APP_ACCESS",
                refreshToken: nil
            )
            let harness = AuthenticatorTestHarness.makeHarness(
                response: .success(data: responseData, statusCode: 200)
            )

            let authenticator = harness.makeClientCredentialsAuthenticator()
            let tokens = try await awaitFirstValue(authenticator.appAccessTokenPublisher())

            #expect(tokens.accessToken == "APP_ACCESS")
            #expect(tokens.refreshToken == nil)
        }

        @Test("Client Credentials loadPersistedTokensPublisher mirrors loadPersistedTokens")
        func clientCredentialsLoadPersistedTokensPublisher() async throws {
            let expected = AuthTestFixtures.sampleTokens(accessToken: "CACHED", refreshToken: nil)
            let harness = AuthenticatorTestHarness.makeHarness(tokens: expected)
            let authenticator = harness.makeClientCredentialsAuthenticator()

            let loaded = try await awaitFirstValue(
                authenticator.loadPersistedTokensPublisher()
            )

            AuthTestFixtures.assertTokensEqual(loaded, expected)
        }
    }

#endif

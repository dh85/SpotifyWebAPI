import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Token Refresh Event Tests")
@MainActor
struct TokenRefreshEventTests {

    actor EventTracker {
        var willStartCalled = false
        var willStartInfo: TokenRefreshInfo?
        var didSucceedCalled = false
        var succeededTokens: SpotifyTokens?
        var didFailCalled = false
        var failedError: Error?
        var callSequence: [String] = []

        func recordWillStart(_ info: TokenRefreshInfo) {
            willStartCalled = true
            willStartInfo = info
            callSequence.append("willStart")
        }

        func recordDidSucceed(_ tokens: SpotifyTokens) {
            didSucceedCalled = true
            succeededTokens = tokens
            callSequence.append("didSucceed")
        }

        func recordDidFail(_ error: Error) {
            didFailCalled = true
            failedError = error
            callSequence.append("didFail")
        }

        func reset() {
            willStartCalled = false
            willStartInfo = nil
            didSucceedCalled = false
            succeededTokens = nil
            didFailCalled = false
            failedError = nil
            callSequence = []
        }
    }

    @Test("onTokenRefreshWillStart called before refresh")
    func willStartCalledBeforeRefresh() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { info in
            Task { @MainActor in
                await tracker.recordWillStart(info)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        // Make a request that will trigger token refresh (token is expired)
        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let called = await tracker.willStartCalled
        #expect(called == true)
    }

    @Test("onTokenRefreshDidSucceed called after successful refresh")
    func didSucceedCalledAfterRefresh() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshDidSucceed { tokens in
            Task { @MainActor in
                await tracker.recordDidSucceed(tokens)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let called = await tracker.didSucceedCalled
        #expect(called == true)
    }

    @Test("TokenRefreshInfo contains correct reason for automatic refresh")
    func infoContainsAutomaticReason() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { info in
            Task { @MainActor in
                await tracker.recordWillStart(info)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let info = await tracker.willStartInfo
        #expect(info?.reason == .automatic)
    }

    @Test("TokenRefreshInfo contains expiration time")
    func infoContainsExpirationTime() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { info in
            Task { @MainActor in
                await tracker.recordWillStart(info)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let info = await tracker.willStartInfo
        #expect(info != nil)
        // Expiration time for expired token should be negative
        #expect(info!.secondsUntilExpiration < 0)
    }

    @Test("onTokenRefreshDidSucceed receives new tokens")
    func didSucceedReceivesNewTokens() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshDidSucceed { tokens in
            Task { @MainActor in
                await tracker.recordDidSucceed(tokens)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let tokens = await tracker.succeededTokens
        #expect(tokens != nil)
        #expect(!tokens!.accessToken.isEmpty)
    }

    @Test("All three callbacks can be set together")
    func allCallbacksCanBeSetTogether() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { info in
            Task { @MainActor in
                await tracker.recordWillStart(info)
            }
        }

        await client.onTokenRefreshDidSucceed { tokens in
            Task { @MainActor in
                await tracker.recordDidSucceed(tokens)
            }
        }

        await client.onTokenRefreshDidFail { error in
            Task { @MainActor in
                await tracker.recordDidFail(error)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let willStart = await tracker.willStartCalled
        let didSucceed = await tracker.didSucceedCalled
        let didFail = await tracker.didFailCalled

        #expect(willStart == true)
        #expect(didSucceed == true)
        #expect(didFail == false)  // No failure in this test
    }

    @Test("Callbacks fire in correct order")
    func callbacksFireInCorrectOrder() async throws {
        let (client, http, _) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { _ in
            Task { @MainActor in
                await tracker.recordWillStart(
                    TokenRefreshInfo(reason: .automatic, secondsUntilExpiration: 0))
            }
        }

        await client.onTokenRefreshDidSucceed { tokens in
            Task { @MainActor in
                await tracker.recordDidSucceed(tokens)
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(10))
        let sequence = await tracker.callSequence

        // willStart should come before didSucceed
        #expect(sequence == ["willStart", "didSucceed"])
    }

    @Test("Multiple requests trigger callbacks multiple times")
    func multipleRequestsTriggerCallbacksMultipleTimes() async throws {
        let (client, http, auth) = makeUserAuthClientWithAuth(initialToken: .mockExpired)
        let tracker = EventTracker()

        await client.onTokenRefreshWillStart { _ in
            Task { @MainActor in
                await tracker.recordWillStart(
                    TokenRefreshInfo(reason: .automatic, secondsUntilExpiration: 0))
            }
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        // Set a new expired token to trigger another refresh on second request
        await auth.setToken(.mockExpired)

        _ = try await client.users.me()

        try await Task.sleep(for: .milliseconds(20))

        let sequence = await tracker.callSequence
        // Should be called twice (once for each refresh)
        #expect(sequence.count == 2)
    }

    @Test("No callbacks fire when not set")
    func noCallbacksWhenNotSet() async throws {
        let (client, http) = makeUserAuthClient()

        // Don't set any callbacks

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        // Test passes if no crash occurs
        #expect(Bool(true))
    }

    @Test("TokenRefreshInfo is Sendable and Equatable")
    func tokenRefreshInfoIsProperType() {
        let info1 = TokenRefreshInfo(reason: .automatic, secondsUntilExpiration: 3600)
        let info2 = TokenRefreshInfo(reason: .automatic, secondsUntilExpiration: 3600)
        let info3 = TokenRefreshInfo(reason: .manual, secondsUntilExpiration: 3600)

        // Equatable
        #expect(info1 == info2)
        #expect(info1 != info3)

        // Sendable is enforced by the compiler
        let _: any Sendable = info1
    }

    @Test("RefreshReason enum cases are distinct")
    func refreshReasonCasesDistinct() {
        let automatic = TokenRefreshInfo.RefreshReason.automatic
        let manual = TokenRefreshInfo.RefreshReason.manual

        #expect(automatic != manual)

        // Sendable and Equatable enforced by compiler
        let _: any Sendable = automatic
    }
}

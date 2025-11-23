import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct InMemoryTokenStoreTests {

    private func makeSampleTokens() -> SpotifyTokens {
        SpotifyTokens(
            accessToken: "ACCESS",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: "user-read-email",
            tokenType: "Bearer"
        )
    }

    @Test
    func loadReturnsNilInitially() async throws {
        let store = InMemoryTokenStore()
        #expect(try await store.load() == nil)
    }

    @Test
    func saveThenLoadReturnsSameTokens() async throws {
        let store = InMemoryTokenStore()
        let tokens = makeSampleTokens()

        try await store.save(tokens)
        let loaded = try await store.load()

        #expect(loaded?.accessToken == tokens.accessToken)
        #expect(loaded?.refreshToken == tokens.refreshToken)
    }

    @Test
    func clearRemovesTokens() async throws {
        let store = InMemoryTokenStore()
        try await store.save(makeSampleTokens())

        try await store.clear()
        #expect(try await store.load() == nil)
    }

    @Test
    func configureFailuresControlsErrorInjection() async throws {
        let store = InMemoryTokenStore()
        await store.configureFailures([.saveFailed])

        await #expect(throws: InMemoryTokenStore.Failure.saveFailed) {
            try await store.save(makeSampleTokens())
        }

        await store.configureFailures([.loadFailed, .clearFailed])

        await #expect(throws: InMemoryTokenStore.Failure.loadFailed) {
            _ = try await store.load()
        }

        await #expect(throws: InMemoryTokenStore.Failure.clearFailed) {
            try await store.clear()
        }
    }

    @Test
    func setFailureTogglesIndividualModes() async throws {
        let store = InMemoryTokenStore()
        await store.setFailure(.saveFailed, isEnabled: true)

        await #expect(throws: InMemoryTokenStore.Failure.saveFailed) {
            try await store.save(makeSampleTokens())
        }

        await store.setFailure(.saveFailed, isEnabled: false)
        try await store.save(makeSampleTokens())  // no throw
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct FileTokenStoreTests {

    private func makeStore() -> FileTokenStore {
        let filename = "spotify_tokens_\(UUID().uuidString).json"
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return FileTokenStore(filename: filename, directory: tmpDir)
    }

    /// Convenience to build a sample token.
    private func makeSampleTokens(
        accessToken: String = "ACCESS",
        refreshToken: String? = "REFRESH",
        expiresOffset: TimeInterval = 3600,
        scope: String? = "user-read-email",
        tokenType: String = "Bearer"
    ) -> SpotifyTokens {
        SpotifyTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresOffset),
            scope: scope,
            tokenType: tokenType
        )
    }

    private func expectTokensEqual(_ loaded: SpotifyTokens?, _ original: SpotifyTokens) {
        guard let loaded else {
            Issue.record("Expected non-nil tokens")
            return
        }
        #expect(loaded.accessToken == original.accessToken)
        #expect(loaded.refreshToken == original.refreshToken)
        #expect(loaded.scope == original.scope)
        #expect(loaded.tokenType == original.tokenType)
        let delta = abs(loaded.expiresAt.timeIntervalSince(original.expiresAt))
        #expect(delta < 1.0)
    }

    @Test
    func fileTokenStoreIntegration() async throws {
        let store = makeStore()
        try await store.clear()
        
        // Load from non-existent file
        #expect(try await store.load() == nil)
        
        // Save and load
        let tokens = makeSampleTokens()
        try await store.save(tokens)
        let loaded = try await store.load()
        expectTokensEqual(loaded, tokens)
        
        // Clear
        try await store.clear()
        #expect(try await store.load() == nil)
    }

    @Test
    func defaultDirectoryFallback() async throws {
        let filename = "spotify_tokens_fallback_\(UUID().uuidString).json"
        let store = FileTokenStore(filename: filename)
        
        try await store.clear()
        let tokens = makeSampleTokens()
        try await store.save(tokens)
        let loaded = try await store.load()
        expectTokensEqual(loaded, tokens)
        try await store.clear()
    }
}

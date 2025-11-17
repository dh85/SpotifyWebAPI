import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct FileTokenStoreTests {

    /// Creates a FileTokenStore that writes into NSTemporaryDirectory(),
    /// with a unique filename so tests don't interfere with each other
    /// or with production caches.
    private func makeStore(testName: String = #function) -> FileTokenStore {
        let unique = UUID().uuidString
        let filename = "spotify_tokens_\(testName)_\(unique).json"
        let tmpDir = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
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

    /// Compares two SpotifyTokens, allowing for sub-second differences in expiresAt
    /// due to ISO8601 encoding/decoding, and forwards source locations from the call site.
    private func expectTokensEqual(
        _ loaded: SpotifyTokens?,
        _ original: SpotifyTokens,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        guard let loaded else {
            Issue.record(
                "Expected non-nil tokens",
                sourceLocation: .init(
                    fileID: String(describing: fileID),
                    filePath: String(describing: filePath),
                    line: Int(line),
                    column: Int(column)
                )
            )
            return
        }

        func expect(
            _ condition: @autoclosure () -> Bool,
            _ message: String
        ) {
            #expect(
                condition(),
                Comment(stringLiteral: message),
                sourceLocation: .init(
                    fileID: String(describing: fileID),
                    filePath: String(describing: filePath),
                    line: Int(line),
                    column: Int(column)
                )
            )
        }

        expect(
            loaded.accessToken == original.accessToken,
            "accessToken mismatch"
        )
        expect(
            loaded.refreshToken == original.refreshToken,
            "refreshToken mismatch"
        )
        expect(loaded.scope == original.scope, "scope mismatch")
        expect(loaded.tokenType == original.tokenType, "tokenType mismatch")

        let delta = abs(loaded.expiresAt.timeIntervalSince(original.expiresAt))
        expect(delta < 1.0, "expiresAt drift > 1 second")
    }

    @Test
    func loadReturnsNilWhenFileDoesNotExist() async throws {
        let store = makeStore()

        // Ensure there's no leftover (defensive, but cheap).
        try await store.clear()

        let loaded = try await store.load()
        #expect(loaded == nil)
    }

    @Test
    func saveThenLoadReturnsSameTokens() async throws {
        let store = makeStore()
        try await store.clear()

        let original = makeSampleTokens(
            accessToken: "ACCESS_1",
            refreshToken: "REFRESH_1",
            expiresOffset: 1234,
            scope: "playlist-read-private",
            tokenType: "Bearer"
        )

        try await store.save(original)

        let loaded = try await store.load()
        expectTokensEqual(loaded, original)
    }

    @Test
    func saveOverwritesExistingTokens() async throws {
        let store = makeStore()
        try await store.clear()

        let first = makeSampleTokens(
            accessToken: "ACCESS_OLD",
            refreshToken: "REFRESH_OLD",
            expiresOffset: 1000
        )
        try await store.save(first)

        let second = makeSampleTokens(
            accessToken: "ACCESS_NEW",
            refreshToken: "REFRESH_NEW",
            expiresOffset: 2000,
            scope: "user-read-email playlist-read-private"
        )
        try await store.save(second)

        let loaded = try await store.load()
        expectTokensEqual(loaded, second)
    }

    @Test
    func clearRemovesPersistedTokens() async throws {
        let store = makeStore()
        try await store.clear()

        let tokens = makeSampleTokens(
            accessToken: "ACCESS_CLEAR",
            refreshToken: "REFRESH_CLEAR"
        )
        try await store.save(tokens)

        // Sanity check that we actually wrote something.
        let loadedBeforeClear = try await store.load()
        expectTokensEqual(loadedBeforeClear, tokens)

        // Now clear and verify it's gone.
        try await store.clear()

        let loadedAfterClear = try await store.load()
        #expect(loadedAfterClear == nil)
    }

    @Test
    func tokenStoreProtocolIsSatisfiedByFileTokenStore() async throws {
        // Exercise the TokenStore protocol usage with FileTokenStore.
        let store: TokenStore = makeStore()
        try await store.clear()

        let tokens = makeSampleTokens(
            accessToken: "ACCESS_PROTO",
            refreshToken: "REFRESH_PROTO"
        )

        try await store.save(tokens)

        let loaded = try await store.load()
        expectTokensEqual(loaded, tokens)

        try await store.clear()
        let afterClear = try await store.load()
        #expect(afterClear == nil)
    }

    /// Covers the `directory == nil` branch in the FileTokenStore initializer,
    /// without touching the CLI's real cache filename.
    @Test
    func defaultInitUsesFallbackDirectoryAndPersists() async throws {
        let filename = "spotify_tokens_default_init_\(UUID().uuidString).json"
        let store = FileTokenStore(filename: filename)  // directory: nil → default branch

        // Best effort clean-up before/after.
        try await store.clear()

        let original = makeSampleTokens(
            accessToken: "ACCESS_DEFAULT",
            refreshToken: "REFRESH_DEFAULT",
            expiresOffset: 1800,
            scope: "user-read-email",
            tokenType: "Bearer"
        )

        try await store.save(original)

        let loaded = try await store.load()
        expectTokensEqual(loaded, original)

        try await store.clear()
    }
}

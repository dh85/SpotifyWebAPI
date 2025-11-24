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

    @Test
    func fileTokenStoreIntegration() async throws {
        let store = makeStore()
        try await store.clear()

        // Load from non-existent file
        #expect(try await store.load() == nil)

        // Save and load
        let tokens = AuthTestFixtures.sampleTokens()
        try await store.save(tokens)
        let loaded = try await store.load()
        AuthTestFixtures.assertTokensEqual(loaded, tokens)

        // Clear
        try await store.clear()
        #expect(try await store.load() == nil)
    }

    @Test
    func defaultDirectoryFallback() async throws {
        let filename = "spotify_tokens_fallback_\(UUID().uuidString).json"
        let store = FileTokenStore(filename: filename)

        try await store.clear()
        let tokens = AuthTestFixtures.sampleTokens()
        try await store.save(tokens)
        let loaded = try await store.load()
        AuthTestFixtures.assertTokensEqual(loaded, tokens)
        try await store.clear()
    }

    @Test
    func usesDocumentsDirectoryWhenAvailable() async throws {
        guard
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            Issue.record("Documents directory unavailable on this platform")
            return
        }

        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try FileManager.default.createDirectory(
                at: documentsURL,
                withIntermediateDirectories: true
            )
        }

        let filename = "spotify_tokens_documents_\(UUID().uuidString).json"
        let store = FileTokenStore(filename: filename)

        let tokens = AuthTestFixtures.sampleTokens(accessToken: "DOC_ACCESS")
        try await store.save(tokens)
        let loaded = try await store.load()
        AuthTestFixtures.assertTokensEqual(loaded, tokens)
        try await store.clear()
    }

    @Test
    func fallsBackToTemporaryDirectoryWhenDocumentsMissing() async throws {
        let filename = "fallback_tokens_\(UUID().uuidString).json"
        let missingDocs = FileManager.default.temporaryDirectory.appendingPathComponent(
            "missing_docs_\(UUID().uuidString)")
        let store = FileTokenStore(
            filename: filename,
            documentsDirectory: { missingDocs }
        )
        let tokens = AuthTestFixtures.sampleTokens(accessToken: "TMP")

        try await store.save(tokens)
        let loaded = try await store.load()
        AuthTestFixtures.assertTokensEqual(loaded, tokens)

        let fallbackFile =
            URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
                filename)
        #expect(FileManager.default.fileExists(atPath: fallbackFile.path))

        try await store.clear()
    }
}

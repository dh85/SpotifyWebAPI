import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct RestrictedFileTokenStoreTests {

    private func makeStore() -> (RestrictedFileTokenStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "restricted_store_\(UUID().uuidString)",
            isDirectory: true
        )
        let store = RestrictedFileTokenStore(
            filename: "tokens.json",
            directory: directory,
            directoryName: directory.lastPathComponent
        )
        let fileURL = directory.appendingPathComponent("tokens.json")
        return (store, fileURL)
    }

    private func sampleTokens(label: String = "ACCESS") -> SpotifyTokens {
        SpotifyTokens(
            accessToken: label,
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: "playlist-read",
            tokenType: "Bearer"
        )
    }

    @Test
    func roundTripSaveLoadAndClear() async throws {
        let (store, fileURL) = makeStore()
        try await store.clear()
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        #expect(try await store.load() == nil)

        let tokens = sampleTokens()
        try await store.save(tokens)

        let loaded = try await store.load()
        #expect(loaded != nil)
        #expect(loaded?.accessToken == tokens.accessToken)
        #expect(loaded?.refreshToken == tokens.refreshToken)

        try await store.clear()
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        #expect(try await store.load() == nil)
    }

    @Test
    func enforcesPosixPermissions() async throws {
        let (store, fileURL) = makeStore()
        let tokens = sampleTokens(label: "PERMS")
        try await store.save(tokens)

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)

        if let permissions = attributes[.posixPermissions] as? NSNumber {
            #expect((permissions.intValue & 0o077) == 0)
        }
        try await store.clear()
    }
}

@Suite
struct TokenStoreFactoryTests {
    @Test
    func factoryReturnsPlatformStore() {
        let store = TokenStoreFactory.defaultStore(service: "com.example.secure", account: "test")
        #if canImport(Security)
            #expect(store is KeychainTokenStore)
        #else
            #expect(store is RestrictedFileTokenStore)
        #endif
    }
}

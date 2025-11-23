import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct RestrictedFileTokenStoreTests {

    private final class ThrowingRemoveFileManager: FileManager, @unchecked Sendable {
        enum StubError: Error, Equatable { case removeFailed }

        override func removeItem(at URL: URL) throws {
            throw StubError.removeFailed
        }
    }

    private final class FailingEncoder: JSONEncoder, @unchecked Sendable {
        enum Failure: Error, Equatable { case encodeFailed }

        override func encode<T>(_ value: T) throws -> Data where T: Encodable {
            throw Failure.encodeFailed
        }
    }

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

    @Test
    func loadThrowsDecodingFailedForCorruptFile() async throws {
        let (store, fileURL) = makeStore()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        try await store.clear()
        let invalidData = "not valid json".data(using: .utf8)!
        try invalidData.write(to: fileURL, options: .atomic)

        do {
            _ = try await store.load()
            Issue.record("Expected load() to throw decodingFailed")
        } catch TokenStoreError.decodingFailed {
            // expected
        } catch {
            Issue.record("Expected decodingFailed, received: \(error)")
        }
    }

    @Test
    func saveWrapsFileSystemErrors() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "restricted_store_readonly_\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: NSNumber(value: Int16(0o500))]
        )
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o700))],
                ofItemAtPath: directory.path
            )
            try? FileManager.default.removeItem(at: directory)
        }

        let store = RestrictedFileTokenStore(
            filename: "tokens.json",
            directory: directory,
            directoryName: directory.lastPathComponent
        )

        do {
            try await store.save(sampleTokens(label: "FAIL"))
            Issue.record("Expected save() to throw fileAccessFailed")
        } catch TokenStoreError.fileAccessFailed {
            // expected
        } catch {
            Issue.record("Expected fileAccessFailed, received: \(error)")
        }
    }

    @Test
    func clearPropagatesFileManagerErrors() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "restricted_store_clear_\(UUID().uuidString)",
            isDirectory: true
        )
        let fileManager = ThrowingRemoveFileManager()
        let store = RestrictedFileTokenStore(
            filename: "tokens.json",
            directory: directory,
            directoryName: directory.lastPathComponent,
            fileManager: fileManager
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        try await store.save(sampleTokens(label: "CLEAR"))

        do {
            try await store.clear()
            Issue.record("Expected clear() to throw fileAccessFailed")
        } catch TokenStoreError.fileAccessFailed(let error as ThrowingRemoveFileManager.StubError) {
            #expect(error == .removeFailed)
        } catch {
            Issue.record("Expected fileAccessFailed(.removeFailed), received: \(error)")
        }
    }

    @Test
    func loadWrapsFileReadErrors() async throws {
        let (store, fileURL) = makeStore()
        try await store.clear()

        let data = Data("restricted".utf8)
        _ = FileManager.default.createFile(atPath: fileURL.path, contents: data)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o000))],
            ofItemAtPath: fileURL.path
        )
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: Int16(0o600))],
                ofItemAtPath: fileURL.path
            )
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
        }

        do {
            _ = try await store.load()
            Issue.record("Expected load() to throw fileAccessFailed")
        } catch TokenStoreError.fileAccessFailed {
            // expected
        } catch {
            Issue.record("Expected fileAccessFailed, received: \(error)")
        }
    }

    @Test
    func savePropagatesEncodingErrors() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "restricted_store_encoding_\(UUID().uuidString)",
            isDirectory: true
        )
        let encoder = FailingEncoder()
        let store = RestrictedFileTokenStore(
            filename: "tokens.json",
            directory: directory,
            directoryName: directory.lastPathComponent,
            encoder: encoder
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            try await store.save(sampleTokens(label: "ENC"))
            Issue.record("Expected save() to throw encodingFailed")
        } catch TokenStoreError.encodingFailed(let error as FailingEncoder.Failure) {
            #expect(error == .encodeFailed)
        } catch {
            Issue.record("Expected encodingFailed, received: \(error)")
        }
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

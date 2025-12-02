import Crypto
import Foundation
import Testing

@testable import SpotifyKit

@Suite struct EncryptedTokenStoreTests {

  @Test
  func saveAndLoad() async throws {
    let key = EncryptedTokenStore.generateKey()
    let store = EncryptedTokenStore(
      filename: "test_\(UUID().uuidString).encrypted",
      wrappingKey: key
    )

    let tokens = SpotifyTokens(
      accessToken: "access123",
      refreshToken: "refresh456",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "user-read-private",
      tokenType: "Bearer"
    )

    try await store.save(tokens)
    let loaded = try await store.load()

    #expect(loaded?.accessToken == "access123")
    #expect(loaded?.refreshToken == "refresh456")
    #expect(loaded?.tokenType == "Bearer")

    try await store.clear()
  }

  @Test
  func loadNonexistent() async throws {
    let key = EncryptedTokenStore.generateKey()
    let store = EncryptedTokenStore(
      filename: "nonexistent_\(UUID().uuidString).encrypted",
      wrappingKey: key
    )

    let loaded = try await store.load()
    #expect(loaded == nil)
  }

  @Test
  func clear() async throws {
    let key = EncryptedTokenStore.generateKey()
    let store = EncryptedTokenStore(
      filename: "test_clear_\(UUID().uuidString).encrypted",
      wrappingKey: key
    )

    let tokens = SpotifyTokens(
      accessToken: "access",
      refreshToken: "refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    try await store.save(tokens)
    try await store.clear()

    let loaded = try await store.load()
    #expect(loaded == nil)
  }

  @Test
  func wrongKeyFails() async throws {
    let key1 = EncryptedTokenStore.generateKey()
    let key2 = EncryptedTokenStore.generateKey()

    let filename = "test_wrongkey_\(UUID().uuidString).encrypted"
    let store1 = EncryptedTokenStore(filename: filename, wrappingKey: key1)
    let store2 = EncryptedTokenStore(filename: filename, wrappingKey: key2)

    let tokens = SpotifyTokens(
      accessToken: "secret",
      refreshToken: "refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    try await store1.save(tokens)

    await #expect(throws: Error.self) {
      try await store2.load()
    }

    try await store1.clear()
  }

  @Test
  func keyExportImport() throws {
    let original = EncryptedTokenStore.generateKey()
    let exported = EncryptedTokenStore.exportKey(original)
    let imported = try EncryptedTokenStore.loadKey(fromBase64: exported)

    #expect(EncryptedTokenStore.exportKey(imported) == exported)
  }

  @Test
  func invalidBase64KeyFails() {
    #expect(throws: Error.self) {
      _ = try EncryptedTokenStore.loadKey(fromBase64: "not-valid-base64!!!")
    }
  }
}

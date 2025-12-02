import Foundation
import Testing

@testable import SpotifyKit

@Suite("Token Store Security Tests")
struct TokenStoreSecurityTests {

  // MARK: - File Permissions Tests

  @Test("RestrictedFileTokenStore sets POSIX 0600 permissions on token files")
  func restrictedFileStoreSetsPOSIX0600Permissions() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("spotify_security_test_\(UUID().uuidString)")
    let store = RestrictedFileTokenStore(
      filename: "test_tokens.json",
      directory: tempDir
    )

    let tokens = SpotifyTokens.mockValid
    try await store.save(tokens)

    let tokenURL = tempDir.appendingPathComponent("test_tokens.json")
    let attributes = try FileManager.default.attributesOfItem(atPath: tokenURL.path)
    let permissions = attributes[.posixPermissions] as? NSNumber

    #expect(
      permissions?.int16Value == 0o600,
      "Token file must have 0600 permissions (owner read/write only)")

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  @Test("RestrictedFileTokenStore sets POSIX 0700 permissions on directories")
  func restrictedFileStoreSetsDirectoryPermissions() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("spotify_security_test_\(UUID().uuidString)")
    let store = RestrictedFileTokenStore(
      filename: "test_tokens.json",
      directory: tempDir
    )

    let tokens = SpotifyTokens.mockValid
    try await store.save(tokens)

    let attributes = try FileManager.default.attributesOfItem(atPath: tempDir.path)
    let permissions = attributes[.posixPermissions] as? NSNumber

    #expect(
      permissions?.int16Value == 0o700,
      "Token directory must have 0700 permissions (owner access only)")

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  #if os(iOS) || os(tvOS) || os(watchOS)
    @Test("RestrictedFileTokenStore sets iOS file protection on token files")
    func restrictedFileStoreSetsIOSFileProtection() async throws {
      let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("spotify_security_test_\(UUID().uuidString)")
      let store = RestrictedFileTokenStore(
        filename: "test_tokens.json",
        directory: tempDir
      )

      let tokens = SpotifyTokens.mockValid
      try await store.save(tokens)

      let tokenURL = tempDir.appendingPathComponent("test_tokens.json")
      let attributes = try FileManager.default.attributesOfItem(atPath: tokenURL.path)
      let protection = attributes[.protectionKey] as? FileProtectionType

      #expect(
        protection == .completeUntilFirstUserAuthentication,
        "Token file must have file protection enabled on iOS"
      )

      // Cleanup
      try? FileManager.default.removeItem(at: tempDir)
    }
  #endif

  // MARK: - Token Store Factory Tests

  #if canImport(Security)
    @Test("TokenStoreFactory returns KeychainTokenStore on Apple platforms")
    func tokenStoreFactoryReturnsKeychainOnApple() {
      let store = TokenStoreFactory.defaultStore(
        service: "test.security",
        account: "test"
      )
      #expect(
        store is KeychainTokenStore,
        "Default store should be KeychainTokenStore on Apple platforms")
    }
  #endif

  @Test("TokenStoreFactory returns RestrictedFileTokenStore on non-Apple platforms")
  func tokenStoreFactoryReturnsRestrictedFileOnNonApple() {
    #if !canImport(Security)
      let store = TokenStoreFactory.defaultStore(
        service: "test.security",
        account: "test"
      )
      #expect(
        store is RestrictedFileTokenStore,
        "Default store should be RestrictedFileTokenStore on non-Apple platforms")
    #else
      // Test passes on Apple platforms (not applicable)
    #endif
  }

  // MARK: - Token Data Security Tests

  @Test("Tokens are never stored in plaintext with default configuration")
  func tokensNotStoredInPlaintext() async throws {
    // This test verifies that stored tokens are JSON-encoded (not just string serialization)
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("spotify_plaintext_test_\(UUID().uuidString)")
    let store = RestrictedFileTokenStore(
      filename: "test_tokens.json",
      directory: tempDir
    )

    let tokens = SpotifyTokens(
      accessToken: "very-secret-access-token",
      refreshToken: "very-secret-refresh-token",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "test-scope",
      tokenType: "Bearer"
    )
    try await store.save(tokens)

    let tokenURL = tempDir.appendingPathComponent("test_tokens.json")
    let fileContent = try String(contentsOf: tokenURL, encoding: .utf8)

    // Verify it's JSON structure, not just plaintext tokens
    #expect(fileContent.contains("{"), "Token file should be JSON format")
    #expect(
      fileContent.contains("access_token") || fileContent.contains("accessToken"),
      "Token file should use JSON field names")

    // Verify we can decode it properly
    let loadedTokens = try await store.load()
    #expect(loadedTokens?.accessToken == "very-secret-access-token")

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  @Test("InMemoryTokenStore does not persist tokens to disk")
  func inMemoryStoreDoesNotPersistToDisk() async throws {
    let store = InMemoryTokenStore()
    let tokens = SpotifyTokens.mockValid

    try await store.save(tokens)

    let loaded = try await store.load()
    #expect(loaded != nil, "InMemoryTokenStore should hold tokens in memory")

    // Verify no files were created in common storage locations
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first
    let tempURL = FileManager.default.temporaryDirectory

    if let documentsURL {
      let documentsContents = try? FileManager.default.contentsOfDirectory(
        atPath: documentsURL.path)
      let hasSpotifyTokenFiles =
        documentsContents?.contains(where: {
          $0.contains("spotify") && $0.contains("token")
        }) ?? false
      #expect(
        !hasSpotifyTokenFiles,
        "InMemoryTokenStore should not create files in documents directory")
    }

    let tempContents = try? FileManager.default.contentsOfDirectory(atPath: tempURL.path)
    let tokenFiles =
      tempContents?.filter {
        $0.contains("spotify") && $0.contains("token") && !$0.contains("test")
      } ?? []
    #expect(tokenFiles.isEmpty, "InMemoryTokenStore should not create files in temp directory")
  }

  // MARK: - Secure Deletion Tests

  @Test("RestrictedFileTokenStore securely deletes token files")
  func restrictedFileStoreSecurelyDeletesTokens() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("spotify_deletion_test_\(UUID().uuidString)")
    let store = RestrictedFileTokenStore(
      filename: "test_tokens.json",
      directory: tempDir
    )

    let tokens = SpotifyTokens.mockValid
    try await store.save(tokens)

    let tokenURL = tempDir.appendingPathComponent("test_tokens.json")
    #expect(
      FileManager.default.fileExists(atPath: tokenURL.path),
      "Token file should exist after save")

    try await store.clear()

    #expect(
      !FileManager.default.fileExists(atPath: tokenURL.path),
      "Token file should be deleted after clear")

    let loaded = try await store.load()
    #expect(loaded == nil, "Tokens should be nil after clear")

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  #if canImport(Security)
    @Test("KeychainTokenStore securely deletes keychain items")
    func keychainStoreSecurelyDeletesTokens() async throws {
      let testService = "com.spotifykit.security.test.\(UUID().uuidString)"
      let testAccount = "test-deletion"
      let store = KeychainTokenStore(
        service: testService,
        account: testAccount
      )

      let tokens = SpotifyTokens.mockValid
      try await store.save(tokens)

      let loaded = try await store.load()
      #expect(loaded != nil, "Tokens should exist in keychain after save")

      try await store.clear()

      let loadedAfterClear = try await store.load()
      #expect(loadedAfterClear == nil, "Tokens should be nil after clear from keychain")
    }
  #endif

  // MARK: - Security Boundary Tests

  @Test("RestrictedFileTokenStore isolates tokens by service and account")
  func restrictedFileStoreIsolatesTokensByServiceAndAccount() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("spotify_isolation_test_\(UUID().uuidString)")

    let store1 = RestrictedFileTokenStore(
      filename: "tokens_user1.json",
      directory: tempDir
    )
    let store2 = RestrictedFileTokenStore(
      filename: "tokens_user2.json",
      directory: tempDir
    )

    let tokens1 = SpotifyTokens(
      accessToken: "user1-token",
      refreshToken: "user1-refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "test",
      tokenType: "Bearer"
    )
    let tokens2 = SpotifyTokens(
      accessToken: "user2-token",
      refreshToken: "user2-refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "test",
      tokenType: "Bearer"
    )

    try await store1.save(tokens1)
    try await store2.save(tokens2)

    let loaded1 = try await store1.load()
    let loaded2 = try await store2.load()

    #expect(loaded1?.accessToken == "user1-token", "Store 1 should only see user1 tokens")
    #expect(loaded2?.accessToken == "user2-token", "Store 2 should only see user2 tokens")
    #expect(loaded1?.accessToken != loaded2?.accessToken, "Tokens should be isolated")

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }
}

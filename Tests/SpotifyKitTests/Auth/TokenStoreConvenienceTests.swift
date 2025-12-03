import Foundation
import Testing
@testable import SpotifyKit

@Suite("TokenStore Convenience Tests")
struct TokenStoreConvenienceTests {
  
  @Test("RestrictedFileTokenStore path factory method")
  func pathFactoryMethod() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tokenPath = tempDir.appendingPathComponent("test_tokens.json")
    
    let store = RestrictedFileTokenStore.at(path: tokenPath)
    
    let tokens = SpotifyTokens(
      accessToken: "test_access",
      refreshToken: "test_refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "user-read-private",
      tokenType: "Bearer"
    )
    
    try await store.save(tokens)
    
    let loaded = try await store.load()
    #expect(loaded?.accessToken == "test_access")
    
    try await store.clear()
    try? FileManager.default.removeItem(at: tokenPath.deletingLastPathComponent())
  }
  
  @Test("Path factory method extracts filename and directory correctly")
  func pathFactoryMethodExtractsComponents() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let path = tempDir.appendingPathComponent("myapp").appendingPathComponent("tokens.json")
    let store = RestrictedFileTokenStore.at(path: path)
    
    // Verify it works by saving and loading
    let tokens = SpotifyTokens(
      accessToken: "test",
      refreshToken: "refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )
    
    try await store.save(tokens)
    let loaded = try await store.load()
    
    #expect(loaded?.accessToken == "test")
    
    try await store.clear()
    try? FileManager.default.removeItem(at: path.deletingLastPathComponent())
  }
}

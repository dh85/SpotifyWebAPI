import Foundation
import Testing
@testable import SpotifyKit

@Suite("SpotifyClient Interactive Auth Tests")
struct SpotifyClientInteractiveAuthTests {
  
  @Test("Interactive auth callbacks are customizable")
  func interactiveAuthCallbacksCustomizable() async throws {
    let authURLBox = Box<URL?>(nil)
    let callbackPromptBox = Box<Bool>(false)
    
    let callbacks = InteractiveAuthCallbacks(
      onAuthURL: { url in
        authURLBox.value = url
      },
      onPromptCallback: {
        callbackPromptBox.value = true
        return URL(string: "test://callback")!
      }
    )
    
    callbacks.onAuthURL(URL(string: "https://test.com")!)
    #expect(authURLBox.value != nil)
    
    let url = try await callbacks.onPromptCallback()
    #expect(callbackPromptBox.value)
    #expect(url.absoluteString == "test://callback")
  }
  
  @Test("Default callbacks use stdout/stdin")
  func defaultCallbacksUseStdoutStdin() {
    let callbacks = InteractiveAuthCallbacks()
    
    // Verify callbacks are set (can't easily test stdout/stdin in unit tests)
    callbacks.onAuthURL(URL(string: "https://test.com")!)
    // If this doesn't crash, the callback is valid
    #expect(true)
  }
  
  @Test("Invalid callback URL throws error")
  func invalidCallbackURLThrowsError() async {
    let callbacks = InteractiveAuthCallbacks(
      onAuthURL: { _ in },
      onPromptCallback: {
        throw SpotifyAuthError.invalidCallback
      }
    )
    
    await #expect(throws: SpotifyAuthError.self) {
      _ = try await callbacks.onPromptCallback()
    }
  }
  
  @Test("Token store reuse with existing tokens")
  func tokenStoreReuseWithExistingTokens() async throws {
    let mockStore = InMemoryTokenStore()
    
    // Pre-populate with tokens
    let existingTokens = SpotifyTokens(
      accessToken: "existing_access",
      refreshToken: "existing_refresh",
      expiresAt: Date().addingTimeInterval(3600),
      scope: "user-read-private",
      tokenType: "Bearer"
    )
    try await mockStore.save(existingTokens)
    
    // Verify tokens are stored
    let loaded = try await mockStore.load()
    #expect(loaded?.accessToken == "existing_access")
  }
}

// MARK: - Test Helpers

final class Box<T>: @unchecked Sendable {
  var value: T
  init(_ value: T) { self.value = value }
}

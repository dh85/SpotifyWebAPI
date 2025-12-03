import Foundation
import Testing

@testable import SpotifyPlaylistFormatter

@Suite("AppConfig Tests")
struct AppConfigTests {

  @Test("Load config successfully")
  func loadConfigSuccess() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: "test_client_id")
    setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: "https://example.com/callback")

    let config = try AppConfig.load()

    #expect(config.clientID == "test_client_id")
    #expect(config.redirectURI.absoluteString == "https://example.com/callback")
  }

  @Test("Missing client ID throws error")
  func missingClientIDError() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    unsetenv("SPOTIFY_CLIENT_ID")
    setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: "https://example.com/callback")

    #expect(throws: AppConfig.ConfigError.missingClientID) {
      try AppConfig.load()
    }
  }

  @Test("Empty client ID throws error")
  func emptyClientIDError() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: "")
    setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: "https://example.com/callback")

    #expect(throws: AppConfig.ConfigError.missingClientID) {
      try AppConfig.load()
    }
  }

  @Test("Missing redirect URI throws error")
  func missingRedirectURIError() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: "test_client_id")
    setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: nil)

    #expect(throws: AppConfig.ConfigError.missingRedirectURI) {
      try AppConfig.load()
    }
  }

  @Test("Empty redirect URI throws error")
  func emptyRedirectURIError() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    setenv("SPOTIFY_CLIENT_ID", "test_client_id", 1)
    unsetenv("SPOTIFY_REDIRECT_URI")
    setenv("SPOTIFY_REDIRECT_URI", "", 1)

    #expect(throws: AppConfig.ConfigError.missingRedirectURI) {
      try AppConfig.load()
    }
  }

  @Test("Invalid redirect URI throws error")
  func invalidRedirectURIError() throws {
    let originalClientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]
    let originalRedirectURI = ProcessInfo.processInfo.environment["SPOTIFY_REDIRECT_URI"]

    defer {
      setEnvironmentVariable("SPOTIFY_CLIENT_ID", value: originalClientID)
      setEnvironmentVariable("SPOTIFY_REDIRECT_URI", value: originalRedirectURI)
    }

    setenv("SPOTIFY_CLIENT_ID", "test_client_id", 1)
    setenv("SPOTIFY_REDIRECT_URI", "ht!tp://not a valid url", 1)

    #expect(throws: (any Error).self) {
      try AppConfig.load()
    }
  }

  @Test("Error descriptions are correct")
  func errorDescriptions() {
    let missingClientIDError = AppConfig.ConfigError.missingClientID
    #expect(
      missingClientIDError.errorDescription
        == "SPOTIFY_CLIENT_ID environment variable is not set. Set it with: export SPOTIFY_CLIENT_ID=\"your_client_id\""
    )

    let missingRedirectURIError = AppConfig.ConfigError.missingRedirectURI
    #expect(
      missingRedirectURIError.errorDescription
        == "SPOTIFY_REDIRECT_URI environment variable is not set. Set it with: export SPOTIFY_REDIRECT_URI=\"your_redirect_uri\""
    )

    let invalidRedirectURIError = AppConfig.ConfigError.invalidRedirectURI("bad-url")
    #expect(invalidRedirectURIError.errorDescription == "Invalid SPOTIFY_REDIRECT_URI: bad-url")
  }

  @Test("AppConfig is Sendable")
  func appConfigIsSendable() {
    let config = AppConfig(
      clientID: "test_id",
      redirectURI: URL(string: "https://example.com")!
    )

    Task {
      // This compiles because AppConfig conforms to Sendable
      let _ = config
    }
  }
}

// Helper function to set environment variables for testing
private func setEnvironmentVariable(_ key: String, value: String?) {
  if let value = value {
    setenv(key, value, 1)
  } else {
    unsetenv(key)
  }
}

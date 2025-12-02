import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyTokensTests {

  @Test
  func detectsExpirationCorrectly() {
    let expired = SpotifyTokens(
      accessToken: "expired",
      refreshToken: "refresh",
      expiresAt: Date(timeIntervalSinceNow: -5),
      scope: "playlist-read-private",
      tokenType: "Bearer"
    )
    #expect(expired.isExpired)

    let valid = SpotifyTokens(
      accessToken: "valid",
      refreshToken: nil,
      expiresAt: Date(timeIntervalSinceNow: 3600),
      scope: nil,
      tokenType: "Bearer"
    )
    #expect(valid.isExpired == false)
  }

  @Test
  func supportsCodableRoundTrip() throws {
    let tokens = SpotifyTokens(
      accessToken: "token",
      refreshToken: "refresh",
      expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
      scope: "scope",
      tokenType: "Bearer"
    )
    try expectCodableRoundTrip(tokens)
  }
}

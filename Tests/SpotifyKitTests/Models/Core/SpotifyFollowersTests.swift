import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyFollowersTests {

  @Test
  func supportsCodableRoundTrip() throws {
    let followers = SpotifyFollowers(
      href: URL(string: "https://api.spotify.com/followers"), total: 42)
    try expectCodableRoundTrip(followers)
  }
}

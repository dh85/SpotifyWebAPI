import Foundation
import Testing

@testable import SpotifyKit

struct MockSpotifyClientDeduplicationTests {

  @Test
  func mockClientDoesNotImplementDeduplication() async throws {
    let mock = MockSpotifyClient()
    mock.mockProfile = CurrentUserProfile(
      id: "test-user",
      displayName: "Test User",
      email: nil,
      country: nil,
      product: nil,
      href: URL(string: "https://api.spotify.com/v1/users/test-user")!,
      externalUrls: SpotifyExternalUrls(spotify: nil),
      images: [],
      followers: SpotifyFollowers(href: nil, total: 0),
      explicitContent: nil,
      type: .user,
      uri: "spotify:user:test-user"
    )

    // Make multiple concurrent calls
    async let profile1 = mock.users.me()
    async let profile2 = mock.users.me()
    async let profile3 = mock.users.me()

    let results = try await [profile1, profile2, profile3]

    // All should succeed
    #expect(results.count == 3)
    for profile in results {
      #expect(profile.id == "test-user")
    }

    // Mock doesn't track request count for deduplication
    #expect(mock.getUsersCalled == true)
  }

  @Test
  func mockClientTracksCallsCorrectly() async throws {
    let mock = MockSpotifyClient()

    // Initially no calls made
    #expect(mock.getUsersCalled == false)
    #expect(mock.pauseCalled == false)
    #expect(mock.playCalled == false)

    // Set up mock data
    mock.mockProfile = CurrentUserProfile(
      id: "test-user",
      displayName: "Test User",
      email: nil,
      country: nil,
      product: nil,
      href: URL(string: "https://api.spotify.com/v1/users/test-user")!,
      externalUrls: SpotifyExternalUrls(spotify: nil),
      images: [],
      followers: SpotifyFollowers(href: nil, total: 0),
      explicitContent: nil,
      type: .user,
      uri: "spotify:user:test-user"
    )

    // Make calls
    _ = try await mock.users.me()
    try await mock.player.pause()
    try await mock.player.resume()

    // Verify tracking
    #expect(mock.getUsersCalled == true)
    #expect(mock.pauseCalled == true)
    #expect(mock.playCalled == true)
  }

  @Test
  func mockClientResetClearsState() async throws {
    let mock = MockSpotifyClient()

    // Set up state
    mock.mockProfile = CurrentUserProfile(
      id: "test-user",
      displayName: "Test User",
      email: nil,
      country: nil,
      product: nil,
      href: URL(string: "https://api.spotify.com/v1/users/test-user")!,
      externalUrls: SpotifyExternalUrls(spotify: nil),
      images: [],
      followers: SpotifyFollowers(href: nil, total: 0),
      explicitContent: nil,
      type: .user,
      uri: "spotify:user:test-user"
    )

    _ = try await mock.users.me()
    #expect(mock.getUsersCalled == true)

    // Reset
    mock.reset()

    // Verify state cleared
    #expect(mock.mockProfile == nil)
    #expect(mock.getUsersCalled == false)
  }
}

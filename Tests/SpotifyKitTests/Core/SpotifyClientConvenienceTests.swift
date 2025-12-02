import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyClientConvenienceTests {

  // MARK: - Search Conveniences
  // Note: Search tests rely on SearchService which is tested separately

  // MARK: - User Shortcuts

  @Test
  @MainActor
  func me_returnsCurrentUserProfile() async throws {
    let (client, http) = await makeUserClient()
    
    let profileData = try TestDataLoader.load("current_user_profile")
    await http.addMockResponse(
      data: profileData,
      statusCode: 200,
      url: URL(string: "https://api.spotify.com/v1/me")!
    )
    
    let profile = try await client.me()
    #expect(profile.id == "mockuser")
  }

  // Note: Library tests rely on service implementations tested separately

  @Test
  @MainActor
  func myTopArtists_returnsArtistArray() async throws {
    let (client, http) = await makeUserClient()
    
    let artistsData = try TestDataLoader.load("top_artists")
    await http.addMockResponse(
      data: artistsData,
      statusCode: 200,
      url: URL(string: "https://api.spotify.com/v1/me/top/artists")!
    )
    
    let artists = try await client.myTopArtists()
    #expect(!artists.isEmpty)
  }

  @Test
  @MainActor
  func myTopTracks_returnsTrackArray() async throws {
    let (client, http) = await makeUserClient()
    
    let tracksData = try TestDataLoader.load("top_tracks")
    await http.addMockResponse(
      data: tracksData,
      statusCode: 200,
      url: URL(string: "https://api.spotify.com/v1/me/top/tracks")!
    )
    
    let tracks = try await client.myTopTracks()
    #expect(!tracks.isEmpty)
  }

  // MARK: - Playback Shortcuts

  @Test
  @MainActor
  func currentPlayback_returnsPlaybackState() async throws {
    let (client, http) = await makeUserClient()
    
    let stateData = try TestDataLoader.load("playback_state")
    await http.addMockResponse(
      data: stateData,
      statusCode: 200,
      url: URL(string: "https://api.spotify.com/v1/me/player")!
    )
    
    let state = try await client.currentPlayback()
    #expect(state != nil)
  }

  @Test
  @MainActor
  func recentlyPlayed_returnsHistoryArray() async throws {
    let (client, http) = await makeUserClient()
    
    let historyData = try TestDataLoader.load("recently_played")
    await http.addMockResponse(
      data: historyData,
      statusCode: 200,
      url: URL(string: "https://api.spotify.com/v1/me/player/recently-played")!
    )
    
    let history = try await client.recentlyPlayed()
    #expect(!history.isEmpty)
  }

  @Test
  @MainActor
  func pause_callsPlayerPause() async throws {
    let (client, http) = await makeUserClient()
    
    await http.addMockResponse(
      data: Data(),
      statusCode: 204,
      url: URL(string: "https://api.spotify.com/v1/me/player/pause")!
    )
    
    try await client.pause()
  }

  @Test
  @MainActor
  func resume_callsPlayerResume() async throws {
    let (client, http) = await makeUserClient()
    
    await http.addMockResponse(
      data: Data(),
      statusCode: 204,
      url: URL(string: "https://api.spotify.com/v1/me/player/play")!
    )
    
    try await client.resume()
  }

  @Test
  @MainActor
  func play_callsPlayerPlay() async throws {
    let (client, http) = await makeUserClient()
    
    await http.addMockResponse(
      data: Data(),
      statusCode: 204,
      url: URL(string: "https://api.spotify.com/v1/me/player/play")!
    )
    
    try await client.play("spotify:track:123")
  }

  // MARK: - App Client Conveniences
  // Note: App client search tests rely on SearchService tested separately

  // MARK: - Helpers

  private func makeUserClient() async -> (SpotifyClient<UserAuthCapability>, MockHTTPClient) {
    let http = MockHTTPClient()
    let token = SpotifyTokens(
      accessToken: "TOKEN",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )
    let auth = MockTokenAuthenticator(token: token)
    let client = SpotifyClient<UserAuthCapability>(backend: auth, httpClient: http)
    return (client, http)
  }

  private func makeAppClient() async -> (SpotifyClient<AppOnlyAuthCapability>, MockHTTPClient) {
    let http = MockHTTPClient()
    let token = SpotifyTokens(
      accessToken: "TOKEN",
      refreshToken: nil,
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )
    let auth = MockTokenAuthenticator(token: token)
    let client = SpotifyClient<AppOnlyAuthCapability>(backend: auth, httpClient: http)
    return (client, http)
  }
}

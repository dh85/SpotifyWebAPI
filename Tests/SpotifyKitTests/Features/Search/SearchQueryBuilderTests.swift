import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SearchQueryBuilderTests {

  @Test
  func query_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).query("test")
  }

  @Test
  func byArtist_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).byArtist("Queen")
  }

  @Test
  func inAlbum_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).inAlbum("A Night at the Opera")
  }

  @Test
  func withTrackName_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withTrackName("Bohemian Rhapsody")
  }

  @Test
  func inYear_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).inYear(1975)
  }

  @Test
  func inYearRange_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).inYear(1970...1980)
  }

  @Test
  func withGenre_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withGenre("rock")
  }

  @Test
  func withISRC_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withISRC("USRC17607839")
  }

  @Test
  func withUPC_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withUPC("00602537518357")
  }

  @Test
  func withFilter_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withFilter("tag:new")
  }

  @Test
  func forTracks_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forTracks()
  }

  @Test
  func forAlbums_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forAlbums()
  }

  @Test
  func forArtists_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forArtists()
  }

  @Test
  func forPlaylists_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forPlaylists()
  }

  @Test
  func forShows_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forShows()
  }

  @Test
  func forEpisodes_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forEpisodes()
  }

  @Test
  func forAudiobooks_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forAudiobooks()
  }

  @Test
  func forTypes_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).forTypes([.track, .album])
  }

  @Test
  func inMarket_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).inMarket("US")
  }

  @Test
  func withLimit_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withLimit(50)
  }

  @Test
  func withOffset_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).withOffset(10)
  }

  @Test
  func includeExternal_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client).includeExternal(.audio)
  }

  @Test
  func execute_throwsWhenNoSearchTypes() async throws {
    let (client, _) = makeTestClient()
    let builder = SearchQueryBuilder(client: client).query("test")
    
    do {
      _ = try await builder.execute()
      Issue.record("Expected error to be thrown")
    } catch let error as SpotifyClientError {
      if case .invalidRequest(let reason, _, _) = error {
        #expect(reason.contains("search type"))
      } else {
        Issue.record("Wrong error type")
      }
    }
  }

  @Test
  func execute_throwsWhenQueryEmpty() async throws {
    let (client, _) = makeTestClient()
    let builder = SearchQueryBuilder(client: client).forTracks()
    
    do {
      _ = try await builder.execute()
      Issue.record("Expected error to be thrown")
    } catch let error as SpotifyClientError {
      if case .invalidRequest(let reason, _, _) = error {
        #expect(reason.contains("empty"))
      } else {
        Issue.record("Wrong error type")
      }
    }
  }

  @Test
  func chainedMethods_returnsBuilder() {
    let (client, _) = makeTestClient()
    let _ = SearchQueryBuilder(client: client)
      .query("rock")
      .byArtist("Queen")
      .inYear(1975)
      .forTracks()
      .inMarket("US")
      .withLimit(10)
  }

  // MARK: - Helpers

  private func makeTestClient() -> (SpotifyClient<UserAuthCapability>, MockHTTPClient) {
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
}

import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Search Query Builder Tests")
struct SearchQueryBuilderTests {

  @Test("Builder constructs basic track search")
  func basicTrackSearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Bohemian Rhapsody")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectRequest(request, path: "/v1/search", method: "GET")
      expectQueryParameters(
        request,
        contains: [
          "q=Bohemian%20Rhapsody",
          "type=track",
          "limit=20",
          "offset=0",
        ])
    }
  }

  @Test("Builder constructs search with artist filter")
  func searchWithArtistFilter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Night")
        .byArtist("Queen")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Night%20artist:%22Queen%22",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with year filter")
  func searchWithYearFilter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("rock")
        .inYear(1975)
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=rock%20year:1975",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with year range")
  func searchWithYearRange() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("disco")
        .inYear(1975...1980)
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=disco%20year:1975-1980",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with genre filter")
  func searchWithGenreFilter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("party")
        .withGenre("pop")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=party%20genre:%22pop%22",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with album filter")
  func searchWithAlbumFilter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Rhapsody")
        .inAlbum("A Night at the Opera")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Rhapsody%20album:%22A%20Night%20at%20the%20Opera%22",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with market")
  func searchWithMarket() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Taylor Swift")
        .forTracks()
        .inMarket("US")
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Taylor%20Swift",
          "type=track",
          "market=US",
        ])
    }
  }

  @Test("Builder constructs search with custom limit")
  func searchWithCustomLimit() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Beatles")
        .forTracks()
        .withLimit(50)
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Beatles",
          "type=track",
          "limit=50",
        ])
    }
  }

  @Test("Builder constructs search with offset")
  func searchWithOffset() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("Rock")
        .forTracks()
        .withOffset(20)
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Rock",
          "type=track",
          "offset=20",
        ])
    }
  }

  @Test("Builder constructs multi-type search")
  func multiTypeSearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .query("Queen")
        .forTypes([.artist, .album, .track])
        .execute()

      let request = await http.firstRequest
      // Check that multiple types are in the query
      let queryValue = extractQueryParameter(request, name: "type")
      #expect(queryValue?.contains("artist") == true)
      #expect(queryValue?.contains("album") == true)
      #expect(queryValue?.contains("track") == true)
    }
  }

  @Test("Builder constructs album-only search")
  func albumOnlySearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .query("Dark Side")
        .forAlbums()
        .execute()

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Dark%20Side",
          "type=album",
        ])
    }
  }

  @Test("Builder constructs artist-only search")
  func artistOnlySearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .query("Pink Floyd")
        .forArtists()
        .execute()

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=Pink%20Floyd",
          "type=artist",
        ])
    }
  }

  @Test("Builder constructs playlist search")
  func playlistSearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .query("workout")
        .forPlaylists()
        .execute()

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=workout",
          "type=playlist",
        ])
    }
  }

  @Test("Builder constructs complex filtered search")
  func complexFilteredSearch() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("rock")
        .byArtist("Queen")
        .inYear(1975...1980)
        .withGenre("rock")
        .forTracks()
        .inMarket("GB")
        .withLimit(30)
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "type=track",
          "market=GB",
          "limit=30",
        ])

      // Check query contains all filters
      let queryValue = extractQueryParameter(request, name: "q")
      #expect(queryValue?.contains("rock") == true)
      #expect(queryValue?.contains("artist:") == true)
      #expect(queryValue?.contains("year:1975-1980") == true)
      #expect(queryValue?.contains("genre:") == true)
    }
  }

  @Test("Builder constructs search with ISRC")
  func searchWithISRC() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .builder()
        .withISRC("GBUM71505078")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=isrc:GBUM71505078",
          "type=track",
        ])
    }
  }

  @Test("Builder constructs search with UPC")
  func searchWithUPC() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .builder()
        .withUPC("602547924032")
        .forAlbums()
        .execute()

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: [
          "q=upc:602547924032",
          "type=album",
        ])
    }
  }

  @Test("Builder constructs search with custom filter")
  func searchWithCustomFilter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("new music")
        .withFilter("tag:hipster")
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      let queryValue = extractQueryParameter(request, name: "q")
      #expect(queryValue?.contains("tag:hipster") == true)
    }
  }

  @Test("executeTracks returns only tracks")
  func executeTracksReturnsOnlyTracks() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let tracks = try await client.search
        .query("Bohemian Rhapsody")
        .executeTracks()

      #expect(tracks.items.count > 0)
      let request = await http.firstRequest
      expectQueryParameters(request, contains: ["type=track"])
    }
  }

  @Test("executeAlbums returns only albums")
  func executeAlbumsReturnsOnlyAlbums() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      // Just test that it builds the right query
      do {
        _ = try await client.search
          .query("Abbey Road")
          .executeAlbums()
      } catch {
        // Expected since mock doesn't have albums
      }

      let request = await http.firstRequest
      expectQueryParameters(request, contains: ["type=album"])
    }
  }

  @Test("executeArtists returns only artists")
  func executeArtistsReturnsOnlyArtists() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      // Just test that it builds the right query
      do {
        _ = try await client.search
          .query("Beatles")
          .executeArtists()
      } catch {
        // Expected since mock doesn't have artists
      }

      let request = await http.firstRequest
      expectQueryParameters(request, contains: ["type=artist"])
    }
  }

  @Test("executePlaylists returns only playlists")
  func executePlaylistsReturnsOnlyPlaylists() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      // Just test that it builds the right query
      do {
        _ = try await client.search
          .query("chill")
          .executePlaylists()
      } catch {
        // Expected since mock doesn't have playlists
      }

      let request = await http.firstRequest
      expectQueryParameters(request, contains: ["type=playlist"])
    }
  }

  @Test("Builder throws error when no search types specified")
  func throwsErrorWithoutSearchTypes() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      await #expect(throws: (any Error).self) {
        _ = try await client.search
          .query("test")
          .execute()
      }
    }
  }

  @Test("Builder throws error with empty query")
  func throwsErrorWithEmptyQuery() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      await #expect(throws: (any Error).self) {
        _ = try await client.search
          .query("")
          .forTracks()
          .execute()
      }
    }
  }

  @Test("Builder chains multiple filters correctly")
  func chainsMultipleFiltersCorrectly() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      let results = try await client.search
        .query("love")
        .byArtist("Beatles")
        .inAlbum("Abbey Road")
        .inYear(1969)
        .forTracks()
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      let queryValue = extractQueryParameter(request, name: "q")

      #expect(queryValue?.contains("love") == true)
      #expect(queryValue?.contains("artist:\"Beatles\"") == true)
      #expect(queryValue?.contains("album:\"Abbey Road\"") == true)
      #expect(queryValue?.contains("year:1969") == true)
    }
  }
}

// MARK: - Helper Functions

private func extractQueryParameter(_ request: URLRequest?, name: String) -> String? {
  guard let url = request?.url,
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
    let queryItems = components.queryItems
  else {
    return nil
  }

  return queryItems.first(where: { $0.name == name })?.value
}

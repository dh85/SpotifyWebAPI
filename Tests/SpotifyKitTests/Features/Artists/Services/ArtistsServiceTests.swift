import Foundation
import Testing

@testable import SpotifyKit

@Suite
@MainActor
struct ArtistsServiceTests {

  // MARK: - Get Artist (Single)

  @Test
  func getArtist_buildsCorrectRequest_andDecodes() async throws {
    try await withMockServiceClient(fixture: "artist_full.json") { client, http in
      let artistId = "0TnOYISbd1XYRBk9myaseg"

      let artist = try await client.artists.get(artistId)

      #expect(artist.id == artistId)
      #expect(artist.name == "Pitbull")

      let request = await http.firstRequest
      #expect(request?.url?.path() == "/v1/artists/\(artistId)")
      #expect(request?.httpMethod == "GET")
    }
  }

  // MARK: - Get Several Artists

  @Test
  func severalArtists_buildsCorrectRequest_andUnwrapsDTO() async throws {
    try await withMockServiceClient(fixture: "artists_several.json") { client, http in
      let ids: Set<String> = [
        "2CIMQHirSU0MQqyYHq0eOx",
        "57dN52uHvrHOxijzpIgu3E",
        "1vCWHaC5f2uS3yhpwWbIA6",
      ]

      let artists = try await client.artists.several(ids: ids)

      #expect(artists.count == 3)
      #expect(artists.first?.name == "deadmau5")

      let request = await http.firstRequest
      #expect(request?.url?.path() == "/v1/artists")

      let actualIDs = extractIDs(from: request?.url)
      #expect(actualIDs == ids)
      #expect(request?.httpMethod == "GET")
    }
  }

  @Test
  func severalArtists_throwsError_whenIDLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    await expectIDBatchLimit(max: 50) { ids in
      _ = try await client.artists.several(ids: ids)
    }
  }

  // MARK: - Get Artist Albums

  @Test
  func artistAlbums_buildsCorrectRequest_withAllParameters() async throws {
    try await withMockServiceClient(fixture: "artist_albums.json") { client, http in
      let page = try await client.artists.albums(
        artistId: "0TnOYISbd1XYRBk9myaseg",
        groups: [.single, .appearsOn],
        market: "ES",
        limit: 10,
        offset: 5
      )

      #expect(page.items.first?.name == "Album One")

      let request = await http.firstRequest
      #expect(
        request?.url?.path() == "/v1/artists/0TnOYISbd1XYRBk9myaseg/albums"
      )
      #expect(request?.httpMethod == "GET")

      let query = request?.url?.query()
      #expect(query?.contains("market=ES") == true)
      #expect(query?.contains("limit=10") == true)
      #expect(query?.contains("offset=5") == true)
      #expect(query?.contains("include_groups=appears_on,single") == true)
    }
  }

  @Test
  func artistAlbums_emptyIncludeGroups_omitsIncludeGroupsQuery() async throws {
    try await withMockServiceClient(fixture: "artist_albums.json") { client, http in
      _ = try await client.artists.albums(
        artistId: "artist123",
        groups: [],  // explicit empty set
        market: "US"
      )

      let request = await http.requests.first
      let query = request?.url?.query()

      #expect(query?.contains("include_groups=") == false)
      #expect(query?.contains("market=US") == true)
    }
  }

  @Test
  func artistAlbums_minimalParameters_omitsOptionalQueries() async throws {
    try await withMockServiceClient(fixture: "artist_albums.json") { client, http in
      _ = try await client.artists.albums(artistId: "artist123")

      let request = await http.firstRequest
      let query = request?.url?.query()

      #expect(query?.contains("market=") == false)
      #expect(query?.contains("include_groups=") == false)
      #expect(query?.contains("limit=20") == true)
      #expect(query?.contains("offset=0") == true)
    }
  }

  @Test
  func artistAlbums_throwError_whenLimitIsOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()

    await expectInvalidRequest(
      reasonEquals: "Limit must be between 1 and 50. You provided 51."
    ) {
      _ = try await client.artists.albums(
        artistId: "artist123",
        limit: 51
      )
    }

    await expectInvalidRequest(
      reasonEquals: "Limit must be between 1 and 50. You provided 0."
    ) {
      _ = try await client.artists.albums(
        artistId: "artist123",
        limit: 0
      )
    }
  }

  @Test
  func artistAlbums_allowsLimitLowerAndUpperBounds() async throws {
    try await withMockServiceClient(fixture: "artist_albums.json") { client, http in
      _ = try await client.artists.albums(artistId: "artist123", limit: 1)
      let request = await http.requests.first
      #expect(request?.url?.query()?.contains("limit=1") == true)
    }

    try await withMockServiceClient(fixture: "artist_albums.json") { client, http in
      _ = try await client.artists.albums(artistId: "artist123", limit: 50)
      let request = await http.requests.first
      #expect(request?.url?.query()?.contains("limit=50") == true)
    }
  }

  @Test
  func streamAlbumPagesBuildsRequests() async throws {
    let (client, http) = try await makeClientWithPaginatedResponse(
      fixture: "artist_albums.json",
      of: SimplifiedAlbum.self,
      offset: 0,
      limit: 25,
      total: 25,
      hasNext: false
    )

    let stream = client.artists.streamAlbumPages(
      for: "artist123",
      includeGroups: [.album],
      market: "US",
      pageSize: 25,
      maxPages: 1
    )
    let offsets = try await collectPageOffsets(stream)

    #expect(offsets == [0])
    let request = await http.firstRequest
    expectRequest(request, path: "/v1/artists/artist123/albums", method: "GET")
    expectMarketParameter(request, market: "US")
    expectQueryParameters(request, contains: ["include_groups=album", "limit=25"])
  }

  @Test
  func streamAlbumsEmitsItems() async throws {
    let (client, _) = try await makeClientWithPaginatedResponse(
      fixture: "artist_albums.json",
      of: SimplifiedAlbum.self,
      offset: 0,
      limit: 30,
      total: 30,
      hasNext: false
    )

    let stream = client.artists.streamAlbums(
      for: "artist123",
      includeGroups: [.album],
      market: "FR",
      pageSize: 30,
      maxItems: 50
    )
    let items = try await collectStreamItems(stream)

    #expect(items.isEmpty == false)
  }

  // MARK: - Get Artist Top Tracks

  @Test
  func topTracks_buildsCorrectRequest_andUnwrapsDTO() async throws {
    try await withMockServiceClient(fixture: "artist_top_tracks.json") { client, http in
      let tracks = try await client.artists.topTracks(
        artistId: "artist123",
        market: "GB"
      )

      #expect(tracks.count == 1)
      #expect(tracks.first?.name == "Top Track 1")

      let request = await http.firstRequest
      #expect(request?.url?.path() == "/v1/artists/artist123/top-tracks")
      let query = request?.url?.query()
      #expect(query == "market=GB")
      #expect(request?.httpMethod == "GET")
    }
  }
}

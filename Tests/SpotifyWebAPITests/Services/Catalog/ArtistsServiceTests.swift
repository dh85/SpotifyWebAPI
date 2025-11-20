import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
@MainActor
struct ArtistsServiceTests {

    // MARK: - Get Artist (Single)

    @Test
    func getArtist_buildsCorrectRequest_andDecodes() async throws {
        let (client, http) = makeUserAuthClient()
        let artistData = try TestDataLoader.load("artist_full.json")
        await http.addMockResponse(data: artistData, statusCode: 200)

        let artistId = "0TnOYISbd1XYRBk9myaseg"

        let artist = try await client.artists.get(artistId)

        #expect(artist.id == artistId)
        #expect(artist.name == "Pitbull")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/artists/\(artistId)")
        #expect(request?.httpMethod == "GET")
    }

    // MARK: - Get Several Artists

    @Test
    func severalArtists_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeUserAuthClient()
        let artistsData = try TestDataLoader.load("artists_several.json")
        await http.addMockResponse(data: artistsData, statusCode: 200)

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

    @Test
    func severalArtists_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        let tooManyIDs = makeIDs(count: 51)

        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.artists.several(ids: tooManyIDs)
        }
    }

    // MARK: - Get Artist Albums

    @Test
    func artistAlbums_buildsCorrectRequest_withAllParameters() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("artist_albums.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let page = try await client.artists.albums(
            for: "0TnOYISbd1XYRBk9myaseg",
            includeGroups: [.single, .appearsOn],
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

    @Test
    func artistAlbums_emptyIncludeGroups_omitsIncludeGroupsQuery() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("artist_albums.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client.artists.albums(
            for: "artist123",
            includeGroups: [],  // explicit empty set
            market: "US"
        )

        let request = await http.requests.first
        let query = request?.url?.query()

        #expect(query?.contains("include_groups=") == false)
        #expect(query?.contains("market=US") == true)
    }

    @Test
    func artistAlbums_minimalParameters_omitsOptionalQueries() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("artist_albums.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client.artists.albums(for: "artist123")

        let request = await http.firstRequest
        let query = request?.url?.query()

        #expect(query?.contains("market=") == false)
        #expect(query?.contains("include_groups=") == false)
        #expect(query?.contains("limit=20") == true)
        #expect(query?.contains("offset=0") == true)
    }

    @Test
    func artistAlbums_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 51."
        ) {
            _ = try await client.artists.albums(
                for: "artist123",
                limit: 51
            )
        }

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 0."
        ) {
            _ = try await client.artists.albums(
                for: "artist123",
                limit: 0
            )
        }
    }

    @Test
    func artistAlbums_allowsLimitLowerAndUpperBounds() async throws {
        let (client1, http1) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("artist_albums.json")
        await http1.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client1.artists.albums(for: "artist123", limit: 1)
        var request = await http1.requests.first
        #expect(request?.url?.query()?.contains("limit=1") == true)

        let (client2, http2) = makeUserAuthClient()
        await http2.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client2.artists.albums(for: "artist123", limit: 50)
        request = await http2.requests.first
        #expect(request?.url?.query()?.contains("limit=50") == true)
    }

    // MARK: - Get Artist Top Tracks

    @Test
    func topTracks_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("artist_top_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        let tracks = try await client.artists.topTracks(
            for: "artist123",
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

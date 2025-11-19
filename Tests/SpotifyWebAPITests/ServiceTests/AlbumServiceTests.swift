import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
@MainActor
struct AlbumServiceTests {

    // MARK: - Public Access Tests (GET /v1/albums)

    @Test
    func getAlbum_buildsCorrectRequest_andDecodes() async throws {
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full.json")
        await http.addMockResponse(data: albumData, statusCode: 200)

        let album = try await client.albums.get("fullalbum_id", market: "US")

        #expect(album.id == "fullalbum_id")
        #expect(album.name == "The Deluxe Test Album")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/albums/fullalbum_id")
        #expect(request?.url?.query()?.contains("market=US") == true)
        #expect(request?.httpMethod == "GET")
    }

    @Test
    func severalAlbums_buildsCorrectRequest_andUnwrapsDTO() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("albums_several.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let albums = try await client.albums.several(
            ids: ["album456", "album123"],
            market: "US"
        )

        #expect(albums.count == 2)
        #expect(albums.first?.name == "Test Album 1")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/albums")
        #expect(
            request?.url?.query()?.contains("ids=album123,album456") == true
        )
        #expect(request?.url?.query()?.contains("market=US") == true)
        #expect(request?.httpMethod == "GET")
    }

    @Test
    func severalAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        let tooManyIDs = makeIDs(count: 21)  // max is 20

        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.several(ids: tooManyIDs)
        }
    }

    @Test
    func getAlbum_nilMarket_omitsQueryParameter() async throws {
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full.json")
        await http.addMockResponse(data: albumData, statusCode: 200)

        _ = try await client.albums.get("album123", market: nil)

        let request = await http.firstRequest
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test
    func severalAlbums_nilMarket_omitsQueryParameter() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("albums_several.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client.albums.several(ids: ["album123"], market: nil)

        let request = await http.firstRequest
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test
    func severalAlbums_allowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let ids = makeIDs(count: 20)  // max is 20
        let albumsData = try TestDataLoader.load("albums_several_20.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let albums = try await client.albums.several(ids: ids)

        #expect(albums.count == 20)
        let query = await http.firstRequest?.url?.query()
        #expect(query?.contains("ids=") == true)
    }

    @Test(arguments: [nil, "US"])
    func albumTracks_buildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("album_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        let page = try await client.albums.tracks(
            "album123",
            market: market,
            limit: 10,
            offset: 5
        )

        #expect(page.items.first?.name == "Track 1")

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/albums/album123/tracks")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("limit=10") == true)
        #expect(request?.url?.query()?.contains("offset=5") == true)

        if let market {
            #expect(
                request?.url?.query()?.contains("market=\(market)") == true,
                "Query should contain market"
            )
        } else {
            #expect(
                request?.url?.query()?.contains("market=") == false,
                "Query should not contain market"
            )
        }
    }

    @Test
    func albumTracks_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 51."
        ) {
            _ = try await client.albums.tracks("id", limit: 51)
        }

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 0."
        ) {
            _ = try await client.albums.tracks("id", limit: 0)
        }
    }

    @Test
    func albumTracks_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("album_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        _ = try await client.albums.tracks("album123")  // default args

        let query = await http.firstRequest?.url?.query()
        #expect(query?.contains("limit=20") == true)
        #expect(query?.contains("offset=0") == true)
    }

    // MARK: - User Access Tests

    @Test
    func savedAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("albums_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        let page = try await client.albums.saved(limit: 10, offset: 5)

        #expect(page.items.first?.album.name == "Test Album")
        #expect(
            page.items.first?.addedAt.description.contains("2024-01-01") == true
        )

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/albums")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.query()?.contains("limit=10") == true)
        #expect(request?.url?.query()?.contains("offset=5") == true)
        #expect(
            request?.url?.query()?.contains("market=") == false,
            "Query should never contain market (API constraint)"
        )
    }

    @Test
    func savedAlbums_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 51."
        ) {
            _ = try await client.albums.saved(limit: 51)
        }

        await expectInvalidRequest(
            reasonEquals: "Limit must be between 1 and 50. You provided 0."
        ) {
            _ = try await client.albums.saved(limit: 0)
        }
    }

    @Test
    func savedAlbums_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("albums_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        _ = try await client.albums.saved()  // defaults

        let query = await http.firstRequest?.url?.query()
        #expect(query?.contains("limit=20") == true)
        #expect(query?.contains("offset=0") == true)
    }

    @Test
    func saveAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20) // Max is 20, test upper bound

        try await client.albums.save(albumIDs)

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/albums")
        #expect(request?.httpMethod == "PUT")

        if let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        {
            #expect(body.ids == albumIDs)
        } else {
            Issue.record("Failed to decode HTTP body or body was nil")
        }
    }

    @Test
    func saveAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        let tooManyIDs = makeIDs(count: 21)  // max is 20

        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.save(tooManyIDs)
        }
    }

    @Test
    func removeAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20)

        try await client.albums.remove(albumIDs)

        let request = await http.firstRequest
        #expect(request?.url?.path() == "/v1/me/albums")
        #expect(request?.httpMethod == "DELETE")

        if let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        {
            #expect(body.ids == albumIDs)
        } else {
            Issue.record("Failed to decode HTTP body or body was nil")
        }
    }

    @Test
    func removeAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        let tooManyIDs = makeIDs(count: 21)  // max is 50

        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.remove(tooManyIDs)
        }
    }

    @Test
    func checkSavedAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = try TestDataLoader.load("check_saved_albums.json")
        await http.addMockResponse(data: checkData, statusCode: 200)

        let albumIDs = makeIDs(count: 20)

        let results = try await client.albums.checkSaved(albumIDs)

        #expect(results == [false, false, false, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true])

        let request = await http.firstRequest
        print(request)
        #expect(request?.url?.path() == "/v1/me/albums/contains")
        #expect(
            request?.url?.query()?.contains(
                "ids=id_1,id_2"
            ) == true
        )
        #expect(request?.httpMethod == "GET")
    }

    @Test
    func checkSavedAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        let tooManyIDs = makeIDs(count: 21)  // max is 20

        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.checkSaved(tooManyIDs)
        }
    }
}

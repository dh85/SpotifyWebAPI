import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct AlbumsServiceTests {

    // MARK: - Public Access Tests

    @Test
    func getBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "album_full.json") { client, http in
            let id = "4aawyAB9vmqN3uQ7FjRGTy"
            let album = try await client.albums.get(id, market: "US")

            #expect(album.id == id)
            #expect(album.name == "Global Warming")
            expectRequest(
                await http.firstRequest, path: "/v1/albums/\(id)", method: "GET",
                queryContains: "market=US")
        }
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "albums_several.json") { client, http in
            let ids: Set<String> = ["album456", "album123"]
            let albums = try await client.albums.several(ids: ids, market: "US")

            #expect(albums.count == 3)
            #expect(albums.first?.name == "TRON: Legacy Reconfigured")

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/albums", method: "GET", queryContains: "market=US")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "album_full.json") { client, http in
            _ = try await client.albums.get("album123", market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "albums_several.json") { client, http in
            _ = try await client.albums.several(ids: ["album123"], market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        try await withMockServiceClient(fixture: "albums_several_20.json") { client, http in
            let ids = makeIDs(count: 20)
            let albums = try await client.albums.several(ids: ids)

            #expect(albums.count == 20)
            #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
        }
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 20) { ids in
            _ = try await client.albums.several(ids: ids)
        }
    }

    // MARK: - Album Tracks Tests

    @Test(arguments: [nil, "US"])
    func tracksBuildsCorrectRequest(market: String?) async throws {
        try await withMockServiceClient(fixture: "album_tracks.json") { client, http in
            let page = try await client.albums.tracks(
                "album123", market: market, limit: 10, offset: 5)

            #expect(page.items.first?.name == "Global Warming (feat. Sensato)")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/albums/album123/tracks", method: "GET",
                queryContains: "limit=10", "offset=5")
            expectMarketParameter(request, market: market)
        }
    }

    @Test
    func tracksUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "album_tracks.json") { client in
            _ = try await client.albums.tracks("album123")
        }
    }

    @Test
    func tracksThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.albums.tracks("id", limit: limit)
        }
    }

    @Test
    func streamTrackPagesBuildsRequests() async throws {
        let (client, http) = try await makeClientWithPaginatedResponse(
            fixture: "album_tracks.json",
            of: SimplifiedTrack.self,
            offset: 0,
            limit: 25,
            total: 25,
            hasNext: false
        )

        let stream = await client.albums.streamTrackPages(
            "album123",
            market: "US",
            pageSize: 25,
            maxPages: 1
        )
        let offsets = try await collectPageOffsets(stream)

        #expect(offsets == [0])
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/albums/album123/tracks", method: "GET")
        expectMarketParameter(request, market: "US")
        #expect(request?.url?.query()?.contains("limit=25") == true)
    }

    @Test
    func streamTracksEmitsItems() async throws {
        let (client, http) = try await makeClientWithPaginatedResponse(
            fixture: "album_tracks.json",
            of: SimplifiedTrack.self,
            offset: 0,
            limit: 30,
            total: 30,
            hasNext: false
        )

        let stream = await client.albums.streamTracks(
            "album123",
            market: "SE",
            pageSize: 30,
            maxItems: 50
        )
        let items = try await collectStreamItems(stream)

        #expect(items.isEmpty == false)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/albums/album123/tracks", method: "GET")
        expectMarketParameter(request, market: "SE")
        #expect(request?.url?.query()?.contains("limit=30") == true)
    }

    // MARK: - User Library Tests

    @Test
    func savedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "albums_saved.json") { client, http in
            let page = try await client.albums.saved(limit: 10, offset: 5)

            #expect(page.items.first?.album.name == "Test Album")
            #expect(page.items.first?.addedAt.description.contains("2024-01-01") == true)

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/albums", method: "GET", queryContains: "limit=10",
                "offset=5")
            #expect(request?.url?.query()?.contains("market=") == false)
        }
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "albums_saved.json") { client in
            _ = try await client.albums.saved()
        }
    }

    @Test
    func savedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.albums.saved(limit: limit)
        }
    }

    @Test
    func allSavedAlbumsFetchesAllPages() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "albums_saved.json",
            of: SavedAlbum.self,
            offset: 0,
            total: 2,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "albums_saved.json",
            of: SavedAlbum.self,
            offset: 50,
            total: 2,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        let albums = try await client.albums.allSavedAlbums()

        #expect(albums.count == 2)
    }

    @Test
    func streamSavedAlbumsRespectsMaxItems() async throws {
        let (client, http) = makeUserAuthClient()
        try await enqueueTwoPageResponses(
            fixture: "albums_saved.json",
            of: SavedAlbum.self,
            http: http
        )

        let stream = await client.albums.streamSavedAlbums(maxItems: 1)
        let collected = try await collectStreamItems(stream)

        #expect(collected.count == 1)
        expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/albums")
    }

    @Test
    func streamSavedAlbumPagesEmitsPages() async throws {
        let (client, http) = makeUserAuthClient()
        try await enqueueTwoPageResponses(
            fixture: "albums_saved.json",
            of: SavedAlbum.self,
            http: http
        )

        let stream = await client.albums.streamSavedAlbumPages(maxPages: 2)
        let offsets = try await collectPageOffsets(stream)
        #expect(offsets == [0, 50])
        expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/albums")
    }

    @Test
    func saveBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20)

        try await client.albums.save(albumIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/albums", method: "PUT", expectedIDs: albumIDs)
    }

    @Test
    func saveThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 20) { ids in
            _ = try await client.albums.save(ids)
        }
    }

    @Test
    func removeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20)

        try await client.albums.remove(albumIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/albums", method: "DELETE", expectedIDs: albumIDs)
    }

    @Test
    func removeThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 20) { ids in
            _ = try await client.albums.remove(ids)
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "check_saved_albums.json") { client, http in
            let albumIDs = makeIDs(count: 20)
            let results = try await client.albums.checkSaved(albumIDs)

            #expect(
                results == [
                    false, false, false, true, true, true, true, true, true, true, true, true, true,
                    true, true, true, true, true, true, true,
                ])

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/me/albums/contains", method: "GET")
            #expect(extractIDs(from: request?.url) == albumIDs)
        }
    }

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 20) { ids in
            _ = try await client.albums.checkSaved(ids)
        }
    }

}

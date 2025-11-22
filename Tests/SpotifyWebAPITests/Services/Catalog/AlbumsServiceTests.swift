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
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full.json")
        await http.addMockResponse(data: albumData, statusCode: 200)

        let id = "4aawyAB9vmqN3uQ7FjRGTy"
        let album = try await client.albums.get(id, market: "US")

        #expect(album.id == id)
        #expect(album.name == "Global Warming")
        expectRequest(
            await http.firstRequest, path: "/v1/albums/\(id)", method: "GET",
            queryContains: "market=US")
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("albums_several.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let ids: Set<String> = ["album456", "album123"]
        let albums = try await client.albums.several(ids: ids, market: "US")

        #expect(albums.count == 3)
        #expect(albums.first?.name == "TRON: Legacy Reconfigured")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/albums", method: "GET", queryContains: "market=US")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full.json")
        await http.addMockResponse(data: albumData, statusCode: 200)

        _ = try await client.albums.get("album123", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("albums_several.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client.albums.several(ids: ["album123"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let ids = makeIDs(count: 20)
        let albumsData = try TestDataLoader.load("albums_several_20.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let albums = try await client.albums.several(ids: ids)

        #expect(albums.count == 20)
        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.several(ids: makeIDs(count: 21))
        }
    }

    // MARK: - Album Tracks Tests

    @Test(arguments: [nil, "US"])
    func tracksBuildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("album_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        let page = try await client.albums.tracks("album123", market: market, limit: 10, offset: 5)

        #expect(page.items.first?.name == "Global Warming (feat. Sensato)")

        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/albums/album123/tracks", method: "GET", queryContains: "limit=10",
            "offset=5")
        expectMarketParameter(request, market: market)
    }

    @Test
    func tracksUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("album_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        _ = try await client.albums.tracks("album123")

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func tracksThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.albums.tracks("id", limit: limit)
        }
    }

    // MARK: - User Library Tests

    @Test
    func savedBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("albums_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        let page = try await client.albums.saved(limit: 10, offset: 5)

        #expect(page.items.first?.album.name == "Test Album")
        #expect(page.items.first?.addedAt.description.contains("2024-01-01") == true)

        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/me/albums", method: "GET", queryContains: "limit=10", "offset=5")
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("albums_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        _ = try await client.albums.saved()

        expectPaginationDefaults(await http.firstRequest)
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
        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.save(makeIDs(count: 21))
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
        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.remove(makeIDs(count: 21))
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = try TestDataLoader.load("check_saved_albums.json")
        await http.addMockResponse(data: checkData, statusCode: 200)

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

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 20") {
            _ = try await client.albums.checkSaved(makeIDs(count: 21))
        }
    }


}

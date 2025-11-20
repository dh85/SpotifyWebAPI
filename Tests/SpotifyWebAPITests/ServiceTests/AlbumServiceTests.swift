import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct AlbumServiceTests {

    // MARK: - Public Access Tests

    @Test
    func getAlbum_buildsCorrectRequest_andDecodes() async throws {
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
    func severalAlbums_buildsCorrectRequest_andUnwrapsDTO() async throws {
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
    func getAlbum_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full.json")
        await http.addMockResponse(data: albumData, statusCode: 200)

        _ = try await client.albums.get("album123", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test(arguments: [nil, "US"])
    func severalAlbums_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let albumsData = try TestDataLoader.load("albums_several.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        _ = try await client.albums.several(ids: ["album123"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalAlbums_allowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let ids = makeIDs(count: 20)
        let albumsData = try TestDataLoader.load("albums_several_20.json")
        await http.addMockResponse(data: albumsData, statusCode: 200)

        let albums = try await client.albums.several(ids: ids)

        #expect(albums.count == 20)
        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 21) {
            _ = try await client.albums.several(ids: makeIDs(count: 21))
        }
    }

    // MARK: - Album Tracks Tests

    @Test(arguments: [nil, "US"])
    func albumTracks_buildsCorrectRequest(market: String?) async throws {
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
    func albumTracks_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("album_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        _ = try await client.albums.tracks("album123")

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func albumTracks_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.albums.tracks("id", limit: limit)
        }
    }

    // MARK: - User Library Tests

    @Test
    func savedAlbums_buildsCorrectRequest() async throws {
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
    func savedAlbums_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("albums_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        _ = try await client.albums.saved()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func savedAlbums_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.albums.saved(limit: limit)
        }
    }

    @Test
    func saveAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20)

        try await client.albums.save(albumIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/albums", method: "PUT", expectedIDs: albumIDs)
    }

    @Test
    func saveAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 21) {
            _ = try await client.albums.save(makeIDs(count: 21))
        }
    }

    @Test
    func removeAlbums_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let albumIDs = makeIDs(count: 20)

        try await client.albums.remove(albumIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/albums", method: "DELETE", expectedIDs: albumIDs)
    }

    @Test
    func removeAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 21) {
            _ = try await client.albums.remove(makeIDs(count: 21))
        }
    }

    @Test
    func checkSavedAlbums_buildsCorrectRequest() async throws {
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
    func checkSavedAlbums_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 21) {
            _ = try await client.albums.checkSaved(makeIDs(count: 21))
        }
    }

    // MARK: - Helper Methods

    private func expectRequest(
        _ request: URLRequest?, path: String, method: String, queryContains: String...
    ) {
        #expect(request?.url?.path() == path)
        #expect(request?.httpMethod == method)
        for query in queryContains {
            #expect(request?.url?.query()?.contains(query) == true)
        }
    }

    private func expectMarketParameter(_ request: URLRequest?, market: String?) {
        if let market {
            #expect(request?.url?.query()?.contains("market=\(market)") == true)
        } else {
            #expect(request?.url?.query()?.contains("market=") == false)
        }
    }

    private func expectPaginationDefaults(_ request: URLRequest?) {
        #expect(request?.url?.query()?.contains("limit=20") == true)
        #expect(request?.url?.query()?.contains("offset=0") == true)
    }

    private func expectIDsInBody(
        _ request: URLRequest?, path: String, method: String, expectedIDs: Set<String>
    ) {
        expectRequest(request, path: path, method: method)

        guard let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        else {
            Issue.record("Failed to decode HTTP body or body was nil")
            return
        }
        #expect(body.ids == expectedIDs)
    }

    private func expectIDLimitError(count: Int, operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 20", operation: operation)
    }
}

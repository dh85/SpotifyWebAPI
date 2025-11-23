import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct TracksServiceTests {

    // MARK: - Public Access Tests

    @Test
    func getBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "track_full.json") { client, http in
            let track = try await client.tracks.get("track_id")

            #expect(track.id == "track_id")
            #expect(track.name == "Test Track")
            expectRequest(await http.firstRequest, path: "/v1/tracks/track_id", method: "GET")
        }
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "track_full.json") { client, http in
            _ = try await client.tracks.get("track123", market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "tracks_several.json") { client, http in
            let ids: Set<String> = ["track1", "track2"]
            let tracks = try await client.tracks.several(ids: ids)

            #expect(tracks.count == 2)
            let request = await http.firstRequest
            expectRequest(request, path: "/v1/tracks", method: "GET")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "tracks_several.json") { client, http in
            _ = try await client.tracks.several(ids: ["track123"], market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        try await withMockServiceClient(fixture: "tracks_several_50.json") { client, _ in
            let ids = makeIDs(count: 50)
            let tracks = try await client.tracks.several(ids: ids)

            #expect(tracks.count == 50)
        }
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.tracks.several(ids: makeIDs(count: 51))
        }
    }

    // MARK: - User Library Tests

    @Test(arguments: [nil, "US"])
    func savedBuildsCorrectRequest(market: String?) async throws {
        try await withMockServiceClient(fixture: "tracks_saved.json") { client, http in
            let page = try await client.tracks.saved(limit: 10, offset: 5, market: market)

            #expect(page.items.first?.track.name == "Test Track")
            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/tracks", method: "GET", queryContains: "limit=10",
                "offset=5")
            expectMarketParameter(request, market: market)
        }
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "tracks_saved.json") { client in
            _ = try await client.tracks.saved()
        }
    }

    @Test
    func savedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.tracks.saved(limit: limit)
        }
    }

    @Test
    func allSavedTracksFetchesAllPages() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 0,
            total: 2,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 50,
            total: 2,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        let tracks = try await client.tracks.allSavedTracks(market: "US")

        #expect(tracks.count == 2)
        expectMarketParameter(await http.firstRequest, market: "US")
    }

    @Test
    func streamSavedTracksRespectsMaxItems() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 0,
            total: 3,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 50,
            total: 3,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        var collected: [SavedTrack] = []
        let stream = await client.tracks.streamSavedTracks(maxItems: 1)
        for try await track in stream {
            collected.append(track)
        }

        #expect(collected.count == 1)
    }

    @Test
    func streamSavedTrackPagesEmitsPages() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 0,
            total: 3,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "tracks_saved.json",
            of: SavedTrack.self,
            offset: 50,
            total: 3,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        var offsets: [Int] = []
        let stream = await client.tracks.streamSavedTrackPages(market: "US")
        for try await page in stream {
            offsets.append(page.offset)
        }

        #expect(offsets == [0, 50])
        expectMarketParameter(await http.firstRequest, market: "US")
    }

    @Test
    func saveBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let trackIDs = makeIDs(count: 50)

        try await client.tracks.save(trackIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/tracks", method: "PUT", expectedIDs: trackIDs)
    }

    @Test
    func saveThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.tracks.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let trackIDs = makeIDs(count: 50)

        try await client.tracks.remove(trackIDs)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/tracks", method: "DELETE", expectedIDs: trackIDs)
    }

    @Test
    func removeThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.tracks.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "check_saved_tracks.json") { client, http in
            let trackIDs = makeIDs(count: 50)
            let results = try await client.tracks.checkSaved(trackIDs)

            #expect(results.count == 50)
            let request = await http.firstRequest
            expectRequest(request, path: "/v1/me/tracks/contains", method: "GET")
            #expect(extractIDs(from: request?.url) == trackIDs)
        }
    }

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.tracks.checkSaved(makeIDs(count: 51))
        }
    }

}

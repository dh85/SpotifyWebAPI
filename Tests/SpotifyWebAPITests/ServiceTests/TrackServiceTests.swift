import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct TrackServiceTests {

    // MARK: - Public Access Tests

    @Test
    func getTrack_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let trackData = try TestDataLoader.load("track_full.json")
        await http.addMockResponse(data: trackData, statusCode: 200)

        let track = try await client.tracks.get("track_id")

        #expect(track.id == "track_id")
        #expect(track.name == "Test Track")
        expectRequest(await http.firstRequest, path: "/v1/tracks/track_id", method: "GET")
    }

    @Test(arguments: [nil, "US"])
    func getTrack_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let trackData = try TestDataLoader.load("track_full.json")
        await http.addMockResponse(data: trackData, statusCode: 200)

        _ = try await client.tracks.get("track123", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalTracks_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("tracks_several.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        let ids: Set<String> = ["track1", "track2"]
        let tracks = try await client.tracks.several(ids: ids)

        #expect(tracks.count == 2)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/tracks", method: "GET")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test(arguments: [nil, "US"])
    func severalTracks_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("tracks_several.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        _ = try await client.tracks.several(ids: ["track123"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalTracks_allowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let ids = makeIDs(count: 50)
        let tracksData = try TestDataLoader.load("tracks_several_50.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)

        let tracks = try await client.tracks.several(ids: ids)

        #expect(tracks.count == 50)
    }

    @Test
    func severalTracks_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            _ = try await client.tracks.several(ids: makeIDs(count: 51))
        }
    }

    // MARK: - User Library Tests

    @Test(arguments: [nil, "US"])
    func savedTracks_buildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("tracks_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        let page = try await client.tracks.saved(limit: 10, offset: 5, market: market)

        #expect(page.items.first?.track.name == "Test Track")
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/tracks", method: "GET", queryContains: "limit=10", "offset=5")
        expectMarketParameter(request, market: market)
    }

    @Test
    func savedTracks_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let savedData = try TestDataLoader.load("tracks_saved.json")
        await http.addMockResponse(data: savedData, statusCode: 200)

        _ = try await client.tracks.saved()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func savedTracks_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.tracks.saved(limit: limit)
        }
    }

    @Test
    func saveTracks_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let trackIDs = makeIDs(count: 50)

        try await client.tracks.save(trackIDs)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/tracks", method: "PUT", expectedIDs: trackIDs)
    }

    @Test
    func saveTracks_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            _ = try await client.tracks.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeTracks_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let trackIDs = makeIDs(count: 50)

        try await client.tracks.remove(trackIDs)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/tracks", method: "DELETE", expectedIDs: trackIDs)
    }

    @Test
    func removeTracks_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            _ = try await client.tracks.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedTracks_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = try TestDataLoader.load("check_saved_tracks.json")
        await http.addMockResponse(data: checkData, statusCode: 200)

        let trackIDs = makeIDs(count: 50)
        let results = try await client.tracks.checkSaved(trackIDs)

        #expect(results.count == 50)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/tracks/contains", method: "GET")
        #expect(extractIDs(from: request?.url) == trackIDs)
    }

    @Test
    func checkSavedTracks_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            _ = try await client.tracks.checkSaved(makeIDs(count: 51))
        }
    }

    // MARK: - Helper Methods

    private func expectIDLimitError(count: Int, operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }

}

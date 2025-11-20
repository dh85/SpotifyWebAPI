import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct ShowServiceTests {

    @Test
    func getShow_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("show_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let id = "showid"
        let show = try await client.shows.get(id, market: "US")

        #expect(show.id == id)
        #expect(show.name == "Show Name")
        expectRequest(await http.firstRequest, path: "/v1/shows/\(id)", method: "GET", queryContains: "market=US")
    }

    @Test(arguments: [nil, "US"])
    func getShow_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("show_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.shows.get("id", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalShows_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("shows_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let ids: Set<String> = ["id1", "id2", "id3"]
        let shows = try await client.shows.several(ids: ids, market: "ES")

        #expect(shows.count == 3)
        #expect(shows.first?.name == "Show 1")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/shows", method: "GET", queryContains: "market=ES")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test(arguments: [nil, "US"])
    func severalShows_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("shows_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.shows.several(ids: ["id"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalShows_allowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("shows_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.shows.several(ids: makeIDs(count: 50))

        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalShows_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.shows.several(ids: makeIDs(count: 51))
        }
    }

    @Test(arguments: [nil, "US"])
    func episodes_buildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("show_episodes.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.shows.episodes(for: "showid", limit: 10, offset: 5, market: market)

        #expect(page.items.first?.name == "Episode 1")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/shows/showid/episodes", method: "GET", queryContains: "limit=10", "offset=5")
        expectMarketParameter(request, market: market)
    }

    @Test
    func episodes_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("show_episodes.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.shows.episodes(for: "showid")

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func episodes_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.shows.episodes(for: "showid", limit: limit)
        }
    }

    @Test
    func savedShows_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("shows_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.shows.saved(limit: 10, offset: 5)

        #expect(page.items.first?.show.name == "Saved Show")

        expectRequest(await http.firstRequest, path: "/v1/me/shows", method: "GET", queryContains: "limit=10", "offset=5")
    }

    @Test
    func savedShows_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("shows_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.shows.saved()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func savedShows_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.shows.saved(limit: limit)
        }
    }

    @Test
    func saveShows_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.shows.save(ids)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/shows", method: "PUT", expectedIDs: ids)
    }

    @Test
    func saveShows_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.shows.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeShows_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.shows.remove(ids)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/shows", method: "DELETE", expectedIDs: ids)
    }

    @Test
    func removeShows_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.shows.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedShows_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("check_saved_shows.json")
        await http.addMockResponse(data: data, statusCode: 200)
        let ids = makeIDs(count: 50)

        let results = try await client.shows.checkSaved(ids)

        #expect(results == [false, false, true])

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/shows/contains", method: "GET")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test
    func checkSavedShows_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.shows.checkSaved(makeIDs(count: 51))
        }
    }

    // MARK: - Helper Methods

    private func expectIDLimitError(operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }
}

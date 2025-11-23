import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct ShowsServiceTests {

    @Test
    func getBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "show_full.json") { client, http in
            let id = "showid"
            let show = try await client.shows.get(id, market: "US")

            #expect(show.id == id)
            #expect(show.name == "Show Name")
            expectRequest(
                await http.firstRequest, path: "/v1/shows/\(id)", method: "GET",
                queryContains: "market=US")
        }
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "show_full.json") { client, http in
            _ = try await client.shows.get("id", market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "shows_several.json") { client, http in
            let ids: Set<String> = ["id1", "id2", "id3"]
            let shows = try await client.shows.several(ids: ids, market: "ES")

            #expect(shows.count == 3)
            #expect(shows.first?.name == "Show 1")

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/shows", method: "GET", queryContains: "market=ES")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "shows_several.json") { client, http in
            _ = try await client.shows.several(ids: ["id"], market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        try await withMockServiceClient(fixture: "shows_several.json") { client, http in
            _ = try await client.shows.several(ids: makeIDs(count: 50))

            #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
        }
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.shows.several(ids: makeIDs(count: 51))
        }
    }

    @Test(arguments: [nil, "US"])
    func episodesBuildsCorrectRequest(market: String?) async throws {
        try await withMockServiceClient(fixture: "show_episodes.json") { client, http in
            let page = try await client.shows.episodes(
                for: "showid", limit: 10, offset: 5, market: market)

            #expect(page.items.first?.name == "Episode 1")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/shows/showid/episodes", method: "GET",
                queryContains: "limit=10", "offset=5")
            expectMarketParameter(request, market: market)
        }
    }

    @Test
    func episodesUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "show_episodes.json") { client in
            _ = try await client.shows.episodes(for: "showid")
        }
    }

    @Test
    func episodesThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.shows.episodes(for: "showid", limit: limit)
        }
    }

    @Test
    func savedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "shows_saved.json") { client, http in
            let page = try await client.shows.saved(limit: 10, offset: 5)

            #expect(page.items.first?.show.name == "Saved Show")

            expectRequest(
                await http.firstRequest, path: "/v1/me/shows", method: "GET",
                queryContains: "limit=10", "offset=5")
        }
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "shows_saved.json") { client in
            _ = try await client.shows.saved()
        }
    }

    @Test
    func savedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.shows.saved(limit: limit)
        }
    }

    @Test
    func allSavedShowsFetchesAllPages() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "shows_saved.json",
            of: SavedShow.self,
            offset: 0,
            total: 2,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "shows_saved.json",
            of: SavedShow.self,
            offset: 50,
            total: 2,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        let shows = try await client.shows.allSavedShows()

        #expect(shows.count == 2)
    }

    @Test
    func saveBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.shows.save(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/shows", method: "PUT", expectedIDs: ids)
    }

    @Test
    func saveThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.shows.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.shows.remove(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/shows", method: "DELETE", expectedIDs: ids)
    }

    @Test
    func removeThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.shows.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "check_saved_shows.json") { client, http in
            let ids = makeIDs(count: 50)

            let results = try await client.shows.checkSaved(ids)

            #expect(results == [false, false, true])

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/me/shows/contains", method: "GET")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.shows.checkSaved(makeIDs(count: 51))
        }
    }


}

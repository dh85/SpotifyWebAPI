import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct EpisodesServiceTests {

    @Test
    func getBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "episode_full.json") { client, http in
            let id = "episodeid"
            let episode = try await client.episodes.get(id, market: "US")

            #expect(episode.id == id)
            #expect(episode.name == "Episode 1")
            expectRequest(
                await http.firstRequest, path: "/v1/episodes/\(id)", method: "GET",
                queryContains: "market=US")
        }
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "episode_full.json") { client, http in
            _ = try await client.episodes.get("id", market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "episodes_several.json") { client, http in
            let ids: Set<String> = ["id1", "id2", "id3"]
            let episodes = try await client.episodes.several(ids: ids, market: "ES")

            #expect(episodes.count == 3)
            #expect(episodes.first?.name == "Episode 1")

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/episodes", method: "GET", queryContains: "market=ES")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "episodes_several.json") { client, http in
            _ = try await client.episodes.several(ids: ["id"], market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        try await withMockServiceClient(fixture: "episodes_several.json") { client, http in
            _ = try await client.episodes.several(ids: makeIDs(count: 50))

            #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
        }
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 50) { ids in
            _ = try await client.episodes.several(ids: ids)
        }
    }

    @Test(arguments: [nil, "US"])
    func savedBuildsCorrectRequest(market: String?) async throws {
        try await withMockServiceClient(fixture: "episodes_saved.json") { client, http in
            let page = try await client.episodes.saved(limit: 10, offset: 5, market: market)

            #expect(page.items.first?.episode.name == "Saved Episode")

            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/episodes", method: "GET", queryContains: "limit=10",
                "offset=5")
            expectMarketParameter(request, market: market)
        }
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "episodes_saved.json") { client in
            _ = try await client.episodes.saved()
        }
    }

    @Test
    func savedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.episodes.saved(limit: limit)
        }
    }

    @Test
    func allSavedEpisodesFetchesAllPages() async throws {
        let (client, http) = makeUserAuthClient()
        let first = try makePaginatedResponse(
            fixture: "episodes_saved.json",
            of: SavedEpisode.self,
            offset: 0,
            total: 2,
            hasNext: true
        )
        let second = try makePaginatedResponse(
            fixture: "episodes_saved.json",
            of: SavedEpisode.self,
            offset: 50,
            total: 2,
            hasNext: false
        )
        await http.addMockResponse(data: first, statusCode: 200)
        await http.addMockResponse(data: second, statusCode: 200)

        let episodes = try await client.episodes.allSavedEpisodes(market: "US")

        #expect(episodes.count == 2)
        expectMarketParameter(await http.firstRequest, market: "US")
    }

    @Test
    func streamSavedEpisodesRespectsMaxItems() async throws {
        let (client, http) = makeUserAuthClient()
        try await enqueueTwoPageResponses(
            fixture: "episodes_saved.json",
            of: SavedEpisode.self,
            http: http
        )

        let stream = client.episodes.streamSavedEpisodes(market: "US", maxItems: 1)
        let collected = try await collectStreamItems(stream)

        #expect(collected.count == 1)
        expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/episodes", market: "US")
    }

    @Test
    func streamSavedEpisodePagesEmitsPages() async throws {
        let (client, http) = makeUserAuthClient()
        try await enqueueTwoPageResponses(
            fixture: "episodes_saved.json",
            of: SavedEpisode.self,
            http: http
        )

        let stream = client.episodes.streamSavedEpisodePages(market: "CA", maxPages: 2)
        let offsets = try await collectPageOffsets(stream)

        #expect(offsets == [0, 50])
        expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/episodes", market: "CA")
    }

    @Test
    func saveBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.episodes.save(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/episodes", method: "PUT", expectedIDs: ids)
    }

    @Test
    func saveThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 50) { ids in
            _ = try await client.episodes.save(ids)
        }
    }

    @Test
    func removeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.episodes.remove(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/episodes", method: "DELETE", expectedIDs: ids)
    }

    @Test
    func removeThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 50) { ids in
            _ = try await client.episodes.remove(ids)
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "check_saved_episodes.json") { client, http in
            let ids = makeIDs(count: 50)

            let results = try await client.episodes.checkSaved(ids)

            #expect(results == [false, false, true])

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/me/episodes/contains", method: "GET")
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDBatchLimit(max: 50) { ids in
            _ = try await client.episodes.checkSaved(ids)
        }
    }

}

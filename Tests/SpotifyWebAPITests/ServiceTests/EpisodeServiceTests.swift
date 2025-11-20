import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct EpisodeServiceTests {

    @Test
    func getEpisode_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episode_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let id = "episodeid"
        let episode = try await client.episodes.get(id, market: "US")

        #expect(episode.id == id)
        #expect(episode.name == "Episode 1")
        expectRequest(await http.firstRequest, path: "/v1/episodes/\(id)", method: "GET", queryContains: "market=US")
    }

    @Test(arguments: [nil, "US"])
    func getEpisode_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episode_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.episodes.get("id", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalEpisodes_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episodes_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let ids: Set<String> = ["id1", "id2", "id3"]
        let episodes = try await client.episodes.several(ids: ids, market: "ES")

        #expect(episodes.count == 3)
        #expect(episodes.first?.name == "Episode 1")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/episodes", method: "GET", queryContains: "market=ES")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test(arguments: [nil, "US"])
    func severalEpisodes_marketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episodes_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.episodes.several(ids: ["id"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalEpisodes_allowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episodes_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.episodes.several(ids: makeIDs(count: 50))

        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalEpisodes_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.episodes.several(ids: makeIDs(count: 51))
        }
    }

    @Test(arguments: [nil, "US"])
    func savedEpisodes_buildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episodes_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.episodes.saved(limit: 10, offset: 5, market: market)

        #expect(page.items.first?.episode.name == "Saved Episode")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/episodes", method: "GET", queryContains: "limit=10", "offset=5")
        expectMarketParameter(request, market: market)
    }

    @Test
    func savedEpisodes_usesDefaultLimitAndOffsetWhenOmitted() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("episodes_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.episodes.saved()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func savedEpisodes_throwError_whenLimitIsOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.episodes.saved(limit: limit)
        }
    }

    @Test
    func saveEpisodes_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.episodes.save(ids)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/episodes", method: "PUT", expectedIDs: ids)
    }

    @Test
    func saveEpisodes_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.episodes.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeEpisodes_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.episodes.remove(ids)

        expectIDsInBody(await http.firstRequest, path: "/v1/me/episodes", method: "DELETE", expectedIDs: ids)
    }

    @Test
    func removeEpisodes_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.episodes.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedEpisodes_buildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("check_saved_episodes.json")
        await http.addMockResponse(data: data, statusCode: 200)
        let ids = makeIDs(count: 50)

        let results = try await client.episodes.checkSaved(ids)

        #expect(results == [false, false, true])

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/episodes/contains", method: "GET")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test
    func checkSavedEpisodes_throwsError_whenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.episodes.checkSaved(makeIDs(count: 51))
        }
    }

    // MARK: - Helper Methods

    private func expectRequest(_ request: URLRequest?, path: String, method: String, queryContains: String...) {
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

    private func expectIDsInBody(_ request: URLRequest?, path: String, method: String, expectedIDs: Set<String>) {
        expectRequest(request, path: path, method: method)

        guard let bodyData = request?.httpBody,
            let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
        else {
            Issue.record("Failed to decode HTTP body or body was nil")
            return
        }
        #expect(body.ids == expectedIDs)
    }

    private func expectIDLimitError(operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }

    private func expectLimitErrors(operation: @escaping (Int) async throws -> Void) async {
        await expectInvalidRequest(reasonEquals: "Limit must be between 1 and 50. You provided 51.") {
            try await operation(51)
        }
        await expectInvalidRequest(reasonEquals: "Limit must be between 1 and 50. You provided 0.") {
            try await operation(0)
        }
    }
}

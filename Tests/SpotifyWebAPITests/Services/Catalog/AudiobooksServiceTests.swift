import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct AudiobooksServiceTests {

    // MARK: - Public Access Tests

    @Test
    func getBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobook_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let id = "7iHfbu1YPACw6oZPAFJtqe"
        let audiobook = try await client.audiobooks.get(id, market: "US")

        #expect(audiobook.id == id)
        #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")
        expectRequest(
            await http.firstRequest, path: "/v1/audiobooks/\(id)", method: "GET",
            queryContains: "market=US")
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobook_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.get("id", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobooks_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let ids: Set<String> = [
            "18yVqkdbdRvS24c0Ilj2ci", "1HGw3J3NxZO1TP1BTtVhpZ", "7iHfbu1YPACw6oZPAFJtqe",
        ]
        let audiobooks = try await client.audiobooks.several(ids: ids, market: "ES")

        #expect(audiobooks.count == 3)
        #expect(audiobooks[2]?.name == "Dune: Book One in the Dune Chronicles")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/audiobooks", method: "GET", queryContains: "market=ES")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobooks_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.several(ids: ["id"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobooks_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.several(ids: makeIDs(count: 50))

        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.audiobooks.several(ids: makeIDs(count: 51))
        }
    }

    @Test(arguments: [nil, "ES"])
    func chaptersBuildsCorrectRequest(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobook_chapters.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.audiobooks.chapters(
            for: "7iHfbu1YPACw6oZPAFJtqe", limit: 10, offset: 5, market: market)

        #expect(page.items.count == 2)
        #expect(page.items.first?.name == "Opening Credits")

        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe/chapters", method: "GET",
            queryContains: "limit=10", "offset=5")
        expectMarketParameter(request, market: market)
    }

    @Test
    func chaptersUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobook_chapters.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.chapters(for: "id")

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func chaptersThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.audiobooks.chapters(for: "id", limit: limit)
        }
    }

    // MARK: - User Access Tests

    @Test
    func savedBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobooks_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let page = try await client.audiobooks.saved(limit: 5, offset: 0)

        #expect(page.items.first?.audiobook.name == "Saved Audiobook Title")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/audiobooks", method: "GET", queryContains: "limit=5")
        #expect(request?.url?.query()?.contains("market=") == false)
    }

    @Test
    func savedUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("audiobooks_saved.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.audiobooks.saved()

        expectPaginationDefaults(await http.firstRequest)
    }

    @Test
    func savedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.audiobooks.saved(limit: limit)
        }
    }

    @Test
    func saveBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.audiobooks.save(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/audiobooks", method: "PUT", expectedIDs: ids)
    }

    @Test
    func saveThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.audiobooks.save(makeIDs(count: 51))
        }
    }

    @Test
    func removeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        let ids = makeIDs(count: 50)

        try await client.audiobooks.remove(ids)

        expectIDsInBody(
            await http.firstRequest, path: "/v1/me/audiobooks", method: "DELETE", expectedIDs: ids)
    }

    @Test
    func removeThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.audiobooks.remove(makeIDs(count: 51))
        }
    }

    @Test
    func checkSavedBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("check_saved_audiobooks.json")
        await http.addMockResponse(data: data, statusCode: 200)
        let ids = makeIDs(count: 50)

        let results = try await client.audiobooks.checkSaved(ids)

        #expect(results == [false, false, true])

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/audiobooks/contains", method: "GET")
        #expect(extractIDs(from: request?.url) == ids)
    }

    @Test
    func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.audiobooks.checkSaved(makeIDs(count: 51))
        }
    }

    // MARK: - Helper Methods

    private func expectIDLimitError(operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct ChaptersServiceTests {

    @Test
    func getBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("chapter_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let id = "chapterid"
        let chapter = try await client.chapters.get(id, market: "US")

        #expect(chapter.id == id)
        #expect(chapter.name == "Chapter 1")
        expectRequest(
            await http.firstRequest, path: "/v1/chapters/\(id)", method: "GET",
            queryContains: "market=US")
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("chapter_full.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.chapters.get("id", market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("chapters_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        let ids = ["id1", "id2", "id3"]
        let chapters = try await client.chapters.several(ids: ids, market: "ES")

        #expect(chapters.count == 3)
        #expect(chapters.first?.name == "Chapter 1")

        let request = await http.firstRequest
        expectRequest(request, path: "/v1/chapters", method: "GET", queryContains: "market=ES")
        #expect(request?.url?.query()?.contains("ids=id1,id2,id3") == true)
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("chapters_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.chapters.several(ids: ["id"], market: market)

        expectMarketParameter(await http.firstRequest, market: market)
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        let (client, http) = makeUserAuthClient()
        let data = try TestDataLoader.load("chapters_several.json")
        await http.addMockResponse(data: data, statusCode: 200)

        _ = try await client.chapters.several(ids: makeIDs(count: 50).map { $0 })

        #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError {
            _ = try await client.chapters.several(ids: makeIDs(count: 51).map { $0 })
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

    private func expectIDLimitError(operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }
}

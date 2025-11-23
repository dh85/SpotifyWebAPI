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
        try await withMockServiceClient(fixture: "chapter_full.json") { client, http in
            let id = "chapterid"
            let chapter = try await client.chapters.get(id, market: "US")

            #expect(chapter.id == id)
            #expect(chapter.name == "Chapter 1")
            expectRequest(
                await http.firstRequest, path: "/v1/chapters/\(id)", method: "GET",
                queryContains: "market=US")
        }
    }

    @Test(arguments: [nil, "US"])
    func getIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "chapter_full.json") { client, http in
            _ = try await client.chapters.get("id", market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "chapters_several.json") { client, http in
            let ids = ["id1", "id2", "id3"]
            let chapters = try await client.chapters.several(ids: ids, market: "ES")

            #expect(chapters.count == 3)
            #expect(chapters.first?.name == "Chapter 1")

            let request = await http.firstRequest
            expectRequest(request, path: "/v1/chapters", method: "GET", queryContains: "market=ES")
            #expect(request?.url?.query()?.contains("ids=id1,id2,id3") == true)
        }
    }

    @Test(arguments: [nil, "US"])
    func severalIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "chapters_several.json") { client, http in
            _ = try await client.chapters.several(ids: ["id"], market: market)

            expectMarketParameter(await http.firstRequest, market: market)
        }
    }

    @Test
    func severalAllowsMaximumIDBatchSize() async throws {
        try await withMockServiceClient(fixture: "chapters_several.json") { client, http in
            _ = try await client.chapters.several(ids: makeIDs(count: 50).map { $0 })

            #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
        }
    }

    @Test
    func severalThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
            _ = try await client.chapters.several(ids: makeIDs(count: 51).map { $0 })
        }
    }


}

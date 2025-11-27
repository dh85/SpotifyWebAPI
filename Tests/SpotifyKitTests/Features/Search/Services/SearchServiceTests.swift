import Foundation
import Testing
@testable import SpotifyKit

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct SearchServiceTests {
    @Test
    func executeBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "search_results.json") { client, http in
            let results = try await client.search.execute(
                query: "test query",
                types: [.track, .album]
            )

            #expect(results.tracks != nil)
            let request = await http.firstRequest
            expectRequest(request, path: "/v1/search", method: "GET", queryContains: "q=test")
        }
    }
    
    @Test
    func executeUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "search_results.json") { client in
            _ = try await client.search.execute(query: "test", types: [.track])
        }
    }
    
    @Test(arguments: [nil, "US"])
    func executeIncludesMarketParameter(market: String?) async throws {
        try await withMockServiceClient(fixture: "search_results.json") { client, http in
            _ = try await client.search.execute(query: "test", types: [.track], market: market)
            expectMarketParameter(await http.firstRequest, market: market)
        }
    }
    
    @Test
    func executeIncludesExternalParameter() async throws {
        try await withMockServiceClient(fixture: "search_results.json") { client, http in
            _ = try await client.search.execute(
                query: "test",
                types: [.track],
                includeExternal: .audio
            )

            let request = await http.firstRequest
            #expect(request?.url?.query()?.contains("include_external=audio") == true)
        }
    }
    
    @Test
    func executeThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.search.execute(query: "test", types: [.track], limit: limit)
        }
    }
}

#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyKit

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("Search Service Combine Tests")
    @MainActor
    struct SearchServiceCombineTests {

        @Test("executePublisher builds correct request")
        func executePublisherBuildsRequest() async throws {
            let results = try await assertPublisherRequest(
                fixture: "search_results.json",
                path: "/v1/search",
                method: "GET",
                queryContains: [
                    "q=test",
                    "type=album,track",
                    "limit=10",
                    "offset=5",
                    "market=US",
                    "include_external=audio",
                ]
            ) { client in
                let search = await client.search
                return search.executePublisher(
                    query: "test query",
                    types: [.track, .album],
                    market: "US",
                    limit: 10,
                    offset: 5,
                    includeExternal: .audio
                )
            }

            #expect(results.tracks != nil)
        }

        @Test(arguments: [nil, "US"])
        func executePublisherIncludesMarketParameter(market: String?) async throws {
            _ = try await assertPublisherRequest(
                fixture: "search_results.json",
                path: "/v1/search",
                method: "GET",
                queryContains: ["type=track"],
                verifyRequest: { request in
                    expectMarketParameter(request, market: market)
                }
            ) { client in
                let search = await client.search
                return search.executePublisher(query: "test", types: [.track], market: market)
            }
        }

        @Test("executePublisher validates limits")
        func executePublisherValidatesLimits() async {
            let (client, _) = makeUserAuthClient()
            let search = await client.search

            await assertLimitOutOfRange { limit in
                _ = try await awaitFirstValue(
                    search.executePublisher(query: "test", types: [.track], limit: limit)
                )
            }
        }
    }

#endif

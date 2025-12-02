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
        return client.search
          .query("test query")
          .forTypes([.track, .album])
          .inMarket("US")
          .withLimit(10)
          .withOffset(5)
          .includeExternal(.audio)
          .executePublisher()
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
        var builder = client.search.query("test").forTracks()
        if let market = market {
          builder = builder.inMarket(market)
        }
        return builder.executePublisher()
      }
    }

    @Test("executePublisher validates limits")
    func executePublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()

      await assertLimitOutOfRange { limit in
        _ = try await awaitFirstValue(
          client.search.query("test").forTracks().withLimit(limit).executePublisher()
        )
      }
    }
  }

#endif

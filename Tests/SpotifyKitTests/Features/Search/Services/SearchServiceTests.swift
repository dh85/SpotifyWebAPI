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
      let results = try await client.search
        .query("test query")
        .forTypes([.track, .album])
        .execute()

      #expect(results.tracks != nil)
      let request = await http.firstRequest
      expectRequest(request, path: "/v1/search", method: "GET", queryContains: "q=test")
    }
  }

  @Test
  func executeUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "search_results.json") { client in
      _ = try await client.search.query("test").forTracks().execute()
    }
  }

  @Test(arguments: [nil, "US"])
  func executeIncludesMarketParameter(market: String?) async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      var builder = client.search.query("test").forTracks()
      if let market = market {
        builder = builder.inMarket(market)
      }
      _ = try await builder.execute()
      expectMarketParameter(await http.firstRequest, market: market)
    }
  }

  @Test
  func executeIncludesExternalParameter() async throws {
    try await withMockServiceClient(fixture: "search_results.json") { client, http in
      _ = try await client.search
        .query("test")
        .forTracks()
        .includeExternal(.audio)
        .execute()

      let request = await http.firstRequest
      #expect(request?.url?.query()?.contains("include_external=audio") == true)
    }
  }

  @Test
  func executeThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.search.query("test").forTracks().withLimit(limit).execute()
    }
  }
}

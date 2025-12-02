#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Browse Service Combine Tests")
  @MainActor
  struct BrowseServiceCombineTests {

    @Test("newReleasesPublisher builds correct request")
    func newReleasesPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "new_releases.json",
        path: "/v1/browse/new-releases",
        method: "GET",
        queryContains: ["limit=10", "offset=5"],
        verifyRequest: { request in
          expectCountryParameter(request, country: "US")
        }
      ) { client in
        let browse = client.browse
        return browse.newReleasesPublisher(country: "US", limit: 10, offset: 5)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("newReleasesPublisher validates limit")
    func newReleasesPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let browse = client.browse

      await expectPublisherLimitValidation { limit in
        browse.newReleasesPublisher(limit: limit)
      }
    }

    @Test("categoryPublisher builds correct request")
    func categoryPublisherBuildsRequest() async throws {
      let category = try await assertPublisherRequest(
        fixture: "category_single.json",
        path: "/v1/browse/categories/party",
        method: "GET",
        verifyRequest: { request in
          expectCountryParameter(request, country: "SE")
          expectLocaleParameter(request, locale: "sv_SE")
        }
      ) { client in
        let browse = client.browse
        return browse.categoryPublisher(id: "party", country: "SE", locale: "sv_SE")
      }

      #expect(category.id == "party")
    }

    @Test("categoriesPublisher builds correct request")
    func categoriesPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "categories_several.json",
        path: "/v1/browse/categories",
        method: "GET",
        queryContains: [
          "country=BR",
          "locale=pt_BR",
          "limit=25",
          "offset=5",
        ]
      ) { client in
        let browse = client.browse
        return browse.categoriesPublisher(
          country: "BR", locale: "pt_BR", limit: 25, offset: 5)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("categoriesPublisher validates limit")
    func categoriesPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let browse = client.browse

      await expectPublisherLimitValidation { limit in
        browse.categoriesPublisher(limit: limit)
      }
    }

    @Test("availableMarketsPublisher builds correct request")
    func availableMarketsPublisherBuildsRequest() async throws {
      let markets = try await assertPublisherRequest(
        fixture: "available_markets.json",
        path: "/v1/markets",
        method: "GET"
      ) { client in
        let browse = client.browse
        return browse.availableMarketsPublisher()
      }

      #expect(markets.contains("US"))
    }
  }

#endif

#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Shows Service Combine Tests")
  @MainActor
  struct ShowsServiceCombineTests {

    @Test("getPublisher builds correct request")
    func getPublisherBuildsCorrectRequest() async throws {
      let show = try await assertPublisherRequest(
        fixture: "show_full.json",
        path: "/v1/shows/showid",
        method: "GET",
        queryContains: ["market=US"]
      ) { client in
        let shows = client.shows
        return shows.getPublisher("showid", market: "US")
      }

      #expect(show.id == "showid")
    }

    @Test("severalPublisher builds correct request")
    func severalPublisherBuildsCorrectRequest() async throws {
      let ids: Set<String> = ["id1", "id2"]
      let result = try await assertPublisherRequest(
        fixture: "shows_several.json",
        path: "/v1/shows",
        method: "GET",
        queryContains: ["market=ES"],
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let shows = client.shows
        return shows.severalPublisher(ids: ids, market: "ES")
      }

      #expect(result.count == 3)
    }

    @Test("episodesPublisher builds correct request")
    func episodesPublisherBuildsCorrectRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "show_episodes.json",
        path: "/v1/shows/showid/episodes",
        method: "GET",
        queryContains: ["limit=10", "offset=5", "market=CA"]
      ) { client in
        let shows = client.shows
        return shows.episodesPublisher(
          for: "showid",
          limit: 10,
          offset: 5,
          market: "CA"
        )
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("episodesPublisher validates limits")
    func episodesPublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let shows = client.shows

      await expectPublisherLimitValidation { limit in
        shows.episodesPublisher(for: "showid", limit: limit)
      }
    }

    @Test("savedPublisher builds correct request")
    func savedPublisherBuildsCorrectRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "shows_saved.json",
        path: "/v1/me/shows",
        method: "GET",
        queryContains: ["limit=10", "offset=5"]
      ) { client in
        let shows = client.shows
        return shows.savedPublisher(limit: 10, offset: 5)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("savedPublisher validates limits")
    func savedPublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let shows = client.shows

      await expectPublisherLimitValidation { limit in
        shows.savedPublisher(limit: limit)
      }
    }


    @Test("savePublisher builds correct request")
    func savePublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 2)
      try await assertIDsMutationPublisher(
        path: "/v1/me/shows",
        method: "PUT",
        ids: ids
      ) { client, ids in
        let shows = client.shows
        return shows.savePublisher(ids)
      }
    }

    @Test("removePublisher builds correct request")
    func removePublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 2)
      try await assertIDsMutationPublisher(
        path: "/v1/me/shows",
        method: "DELETE",
        ids: ids
      ) { client, ids in
        let shows = client.shows
        return shows.removePublisher(ids)
      }
    }

    @Test("checkSavedPublisher builds correct request")
    func checkSavedPublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 3)
      let results = try await assertPublisherRequest(
        fixture: "check_saved_shows.json",
        path: "/v1/me/shows/contains",
        method: "GET",
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let shows = client.shows
        return shows.checkSavedPublisher(ids)
      }

      #expect(results.count == 3)
    }
  }

#endif

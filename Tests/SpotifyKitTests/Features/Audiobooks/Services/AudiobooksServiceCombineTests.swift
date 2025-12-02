#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Audiobooks Service Combine Tests")
  @MainActor
  struct AudiobooksServiceCombineTests {

    @Test("getPublisher emits audiobook")
    func getPublisherEmitsAudiobook() async throws {
      let audiobook = try await assertPublisherRequest(
        fixture: "audiobook_full.json",
        path: "/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe",
        method: "GET",
        queryContains: ["market=US"]
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.getPublisher("7iHfbu1YPACw6oZPAFJtqe", market: "US")
      }

      #expect(audiobook.id == "7iHfbu1YPACw6oZPAFJtqe")
    }

    @Test("severalPublisher builds correct request")
    func severalPublisherBuildsRequest() async throws {
      let ids: Set<String> = [
        "18yVqkdbdRvS24c0Ilj2ci",
        "1HGw3J3NxZO1TP1BTtVhpZ",
        "7iHfbu1YPACw6oZPAFJtqe",
      ]
      let result = try await assertPublisherRequest(
        fixture: "audiobooks_several.json",
        path: "/v1/audiobooks",
        method: "GET",
        queryContains: ["market=ES"],
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.severalPublisher(ids: ids, market: "ES")
      }

      #expect(result.count == ids.count)
    }

    @Test("severalPublisher validates ID limits")
    func severalPublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let audiobooks = client.audiobooks

      await expectPublisherIDBatchLimit(max: 50) { ids in
        audiobooks.severalPublisher(ids: ids)
      }
    }

    @Test("chaptersPublisher builds correct request")
    func chaptersPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "audiobook_chapters.json",
        path: "/v1/audiobooks/audiobook123/chapters",
        method: "GET",
        queryContains: ["limit=15", "offset=5"],
        verifyRequest: { request in
          expectMarketParameter(request, market: "GB")
        }
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.chaptersPublisher(
          for: "audiobook123",
          limit: 15,
          offset: 5,
          market: "GB"
        )
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("chaptersPublisher validates limit")
    func chaptersPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let audiobooks = client.audiobooks

      await expectPublisherLimitValidation { limit in
        audiobooks.chaptersPublisher(for: "id", limit: limit)
      }
    }

    @Test("savedPublisher builds correct request")
    func savedPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "audiobooks_saved.json",
        path: "/v1/me/audiobooks",
        method: "GET",
        queryContains: ["limit=10", "offset=2"]
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.savedPublisher(limit: 10, offset: 2)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("savedPublisher validates limit")
    func savedPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let audiobooks = client.audiobooks

      await expectPublisherLimitValidation { limit in
        audiobooks.savedPublisher(limit: limit)
      }
    }

    @Test("allSavedAudiobooksPublisher aggregates pages")
    func allSavedAudiobooksPublisherAggregatesPages() async throws {
      try await assertAggregatesPages(
        fixture: "audiobooks_saved.json",
        of: SavedAudiobook.self
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.allSavedAudiobooksPublisher()
      }
    }

    @Test("savePublisher builds correct request")
    func savePublisherBuildsRequest() async throws {
      let ids = makeIDs(count: 50)
      try await assertIDsMutationPublisher(
        path: "/v1/me/audiobooks",
        method: "PUT",
        ids: ids
      ) { client, ids in
        let audiobooks = client.audiobooks
        return audiobooks.savePublisher(ids)
      }
    }

    @Test("savePublisher validates ID limits")
    func savePublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let audiobooks = client.audiobooks

      await expectPublisherIDBatchLimit(max: 50) { ids in
        audiobooks.savePublisher(ids)
      }
    }

    @Test("removePublisher builds correct request")
    func removePublisherBuildsRequest() async throws {
      let ids = makeIDs(count: 25)
      try await assertIDsMutationPublisher(
        path: "/v1/me/audiobooks",
        method: "DELETE",
        ids: ids
      ) { client, ids in
        let audiobooks = client.audiobooks
        return audiobooks.removePublisher(ids)
      }
    }

    @Test("checkSavedPublisher builds correct request")
    func checkSavedPublisherBuildsRequest() async throws {
      let ids = makeIDs(count: 50)
      let result = try await assertPublisherRequest(
        fixture: "check_saved_audiobooks.json",
        path: "/v1/me/audiobooks/contains",
        method: "GET",
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let audiobooks = client.audiobooks
        return audiobooks.checkSavedPublisher(ids)
      }

      #expect(result.count == 3)
    }
  }

#endif

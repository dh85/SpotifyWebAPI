#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Chapters Service Combine Tests")
  @MainActor
  struct ChaptersServiceCombineTests {

    @Test("getPublisher emits chapter")
    func getPublisherEmitsChapter() async throws {
      let chapter = try await assertPublisherRequest(
        fixture: "chapter_full.json",
        path: "/v1/chapters/chapter123",
        method: "GET",
        queryContains: ["market=US"]
      ) { client in
        let chapters = client.chapters
        return chapters.getPublisher("chapter123", market: "US")
      }

      #expect(chapter.name.isEmpty == false)
    }

    @Test("severalPublisher builds correct request")
    func severalPublisherBuildsRequest() async throws {
      let ids = ["c1", "c2", "c3"]
      let chapters = try await assertPublisherRequest(
        fixture: "chapters_several.json",
        path: "/v1/chapters",
        method: "GET",
        queryContains: ["market=ES"],
        verifyRequest: { request in
          #expect(request?.url?.query()?.contains("ids=c1,c2,c3") == true)
        }
      ) { client in
        let chaptersService = client.chapters
        return chaptersService.severalPublisher(ids: ids, market: "ES")
      }

      #expect(chapters.count == ids.count)
    }

    @Test("severalPublisher validates limit")
    func severalPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let chapters = client.chapters
      let ids = makeIDs(count: 51).map { $0 }

      do {
        _ = try await awaitFirstValue(chapters.severalPublisher(ids: ids))
        Issue.record("Expected validation error for >50 IDs")
      } catch let error as SpotifyClientError {
        switch error {
        case .invalidRequest(let reason, _, _):
          #expect(reason.contains("Maximum of 50"))
        default:
          Issue.record("Unexpected SpotifyClientError: \(error)")
        }
      } catch {
        Issue.record("Unexpected error: \(error)")
      }
    }
  }

#endif

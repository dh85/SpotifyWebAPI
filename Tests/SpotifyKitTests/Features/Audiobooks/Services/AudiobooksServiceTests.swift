import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite
@MainActor
struct AudiobooksServiceTests {

  // MARK: - Public Access Tests

  @Test
  func getBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "audiobook_full.json") { client, http in
      let id = "7iHfbu1YPACw6oZPAFJtqe"
      let audiobook = try await client.audiobooks.get(id, market: "US")

      #expect(audiobook.id == id)
      #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")
      expectRequest(
        await http.firstRequest, path: "/v1/audiobooks/\(id)", method: "GET",
        queryContains: "market=US")
    }
  }

  @Test(arguments: [nil, "US"])
  func getIncludesMarketParameter(market: String?) async throws {
    try await withMockServiceClient(fixture: "audiobook_full.json") { client, http in
      _ = try await client.audiobooks.get("id", market: market)

      expectMarketParameter(await http.firstRequest, market: market)
    }
  }

  @Test
  func severalBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "audiobooks_several.json") { client, http in
      let ids: Set<String> = [
        "18yVqkdbdRvS24c0Ilj2ci", "1HGw3J3NxZO1TP1BTtVhpZ", "7iHfbu1YPACw6oZPAFJtqe",
      ]
      let audiobooks = try await client.audiobooks.several(ids: ids, market: "ES")

      #expect(audiobooks.count == 3)
      #expect(audiobooks[2]?.name == "Dune: Book One in the Dune Chronicles")

      let request = await http.firstRequest
      expectRequest(
        request, path: "/v1/audiobooks", method: "GET", queryContains: "market=ES")
      #expect(extractIDs(from: request?.url) == ids)
    }
  }

  @Test(arguments: [nil, "US"])
  func severalIncludesMarketParameter(market: String?) async throws {
    try await withMockServiceClient(fixture: "audiobooks_several.json") { client, http in
      _ = try await client.audiobooks.several(ids: ["id"], market: market)

      expectMarketParameter(await http.firstRequest, market: market)
    }
  }

  @Test
  func severalAllowsMaximumIDBatchSize() async throws {
    try await withMockServiceClient(fixture: "audiobooks_several.json") { client, http in
      _ = try await client.audiobooks.several(ids: makeIDs(count: 50))

      #expect(await http.firstRequest?.url?.query()?.contains("ids=") == true)
    }
  }

  @Test
  func severalThrowsErrorWhenIDLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    await expectIDBatchLimit(max: 50) { ids in
      _ = try await client.audiobooks.several(ids: ids)
    }
  }

  @Test(arguments: [nil, "ES"])
  func chaptersBuildsCorrectRequest(market: String?) async throws {
    try await withMockServiceClient(fixture: "audiobook_chapters.json") { client, http in
      let page = try await client.audiobooks.chapters(
        for: "7iHfbu1YPACw6oZPAFJtqe", limit: 10, offset: 5, market: market)

      #expect(page.items.count == 2)
      #expect(page.items.first?.name == "Opening Credits")

      let request = await http.firstRequest
      expectRequest(
        request, path: "/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe/chapters", method: "GET",
        queryContains: "limit=10", "offset=5")
      expectMarketParameter(request, market: market)
    }
  }

  @Test
  func chaptersUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "audiobook_chapters.json") { client in
      _ = try await client.audiobooks.chapters(for: "id")
    }
  }

  @Test
  func chaptersThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.audiobooks.chapters(for: "id", limit: limit)
    }
  }

  @Test
  func streamChapterPagesBuildsRequests() async throws {
    let (client, http) = try await makeClientWithPaginatedResponse(
      fixture: "audiobook_chapters.json",
      of: SimplifiedChapter.self,
      offset: 0,
      limit: 40,
      total: 40,
      hasNext: false
    )

    let stream = client.audiobooks.streamChapterPages(
      for: "audiobook123",
      market: "GB",
      pageSize: 40,
      maxPages: 1
    )
    let offsets = try await collectPageOffsets(stream)

    #expect(offsets == [0])
    let request = await http.firstRequest
    expectRequest(request, path: "/v1/audiobooks/audiobook123/chapters", method: "GET")
    expectMarketParameter(request, market: "GB")
    #expect(request?.url?.query()?.contains("limit=40") == true)
  }

  @Test
  func streamChaptersEmitsItems() async throws {
    let (client, http) = try await makeClientWithPaginatedResponse(
      fixture: "audiobook_chapters.json",
      of: SimplifiedChapter.self,
      offset: 0,
      limit: 35,
      total: 35,
      hasNext: false
    )

    let stream = client.audiobooks.streamChapters(
      for: "audiobook123",
      market: "DE",
      pageSize: 35,
      maxItems: 35
    )
    let items = try await collectStreamItems(stream)

    #expect(items.isEmpty == false)
    let request = await http.firstRequest
    expectRequest(request, path: "/v1/audiobooks/audiobook123/chapters", method: "GET")
    expectMarketParameter(request, market: "DE")
    #expect(request?.url?.query()?.contains("limit=35") == true)
  }

  // MARK: - User Access Tests

  @Test
  func savedBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "audiobooks_saved.json") { client, http in
      let page = try await client.audiobooks.saved(limit: 5, offset: 0)

      #expect(page.items.first?.audiobook.name == "Saved Audiobook Title")

      let request = await http.firstRequest
      expectRequest(
        request, path: "/v1/me/audiobooks", method: "GET", queryContains: "limit=5")
      #expect(request?.url?.query()?.contains("market=") == false)
    }
  }

  @Test
  func savedUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "audiobooks_saved.json") { client in
      _ = try await client.audiobooks.saved()
    }
  }

  @Test
  func savedThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.audiobooks.saved(limit: limit)
    }
  }

  @Test
  func streamSavedAudiobooksRespectsMaxItems() async throws {
    let (client, http) = makeUserAuthClient()
    try await enqueueTwoPageResponses(
      fixture: "audiobooks_saved.json",
      of: SavedAudiobook.self,
      http: http
    )

    let stream = client.audiobooks.streamSavedAudiobooks(maxItems: 1)
    let collected = try await collectStreamItems(stream)

    #expect(collected.count == 1)
    expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/audiobooks")
  }

  @Test
  func streamSavedAudiobookPagesEmitsPages() async throws {
    let (client, http) = makeUserAuthClient()
    try await enqueueTwoPageResponses(
      fixture: "audiobooks_saved.json",
      of: SavedAudiobook.self,
      http: http
    )

    let stream = client.audiobooks.streamSavedAudiobookPages(maxPages: 2)
    let offsets = try await collectPageOffsets(stream)

    #expect(offsets == [0, 50])
    expectSavedStreamRequest(await http.firstRequest, path: "/v1/me/audiobooks")
  }

  @Test
  func saveBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)
    let ids = makeIDs(count: 50)

    try await client.audiobooks.save(ids)

    expectIDsInBody(
      await http.firstRequest, path: "/v1/me/audiobooks", method: "PUT", expectedIDs: ids)
  }

  @Test
  func saveThrowsErrorWhenIDLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    await expectIDBatchLimit(max: 50) { ids in
      _ = try await client.audiobooks.save(ids)
    }
  }

  @Test
  func removeBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)
    let ids = makeIDs(count: 50)

    try await client.audiobooks.remove(ids)

    expectIDsInBody(
      await http.firstRequest, path: "/v1/me/audiobooks", method: "DELETE", expectedIDs: ids)
  }

  @Test
  func removeThrowsErrorWhenIDLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    await expectIDBatchLimit(max: 50) { ids in
      _ = try await client.audiobooks.remove(ids)
    }
  }

  @Test
  func checkSavedBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "check_saved_audiobooks.json") { client, http in
      let ids = makeIDs(count: 50)

      let results = try await client.audiobooks.checkSaved(ids)

      #expect(results == [false, false, true])

      let request = await http.firstRequest
      expectRequest(request, path: "/v1/me/audiobooks/contains", method: "GET")
      #expect(extractIDs(from: request?.url) == ids)
    }
  }

  @Test
  func checkSavedThrowsErrorWhenIDLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    await expectIDBatchLimit(max: 50) { ids in
      _ = try await client.audiobooks.checkSaved(ids)
    }
  }

}

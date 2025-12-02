import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Library Service Extensions Tests")
@MainActor
struct LibraryServiceExtensionsTests {

  @Test("Albums saveAll chunks into batches of 20")
  func albumsSaveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...45).map { "album\($0)" }
    try await client.albums.saveAll(ids)

    let requests = await http.requests
    #expect(requests.count == 3)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/albums" })
  }

  @Test("Albums removeAll chunks into batches of 20")
  func albumsRemoveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...35).map { "album\($0)" }
    try await client.albums.removeAll(ids)

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/albums" })
  }

  @Test("Tracks saveAll chunks into batches of 50")
  func tracksSaveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...120).map { "track\($0)" }
    try await client.tracks.saveAll(ids)

    let requests = await http.requests
    #expect(requests.count == 3)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/tracks" })
  }

  @Test("Tracks removeAll chunks into batches of 50")
  func tracksRemoveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...80).map { "track\($0)" }
    try await client.tracks.removeAll(ids)

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/tracks" })
  }

  @Test("Shows saveAll chunks into batches of 50")
  func showsSaveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...90).map { "show\($0)" }
    try await client.shows.saveAll(ids)

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/shows" })
  }

  @Test("Shows removeAll chunks into batches of 50")
  func showsRemoveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...75).map { "show\($0)" }
    try await client.shows.removeAll(ids)

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/shows" })
  }

  @Test("Episodes saveAll handles single batch")
  func episodesSaveAllSingleBatch() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...30).map { "episode\($0)" }
    try await client.episodes.saveAll(ids)

    let requests = await http.requests
    #expect(requests.count == 1)
  }

  @Test("Episodes removeAll chunks into batches of 50")
  func episodesRemoveAllChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)
    await http.addMockResponse(data: Data(), statusCode: 200)

    let ids = (1...60).map { "episode\($0)" }
    try await client.episodes.removeAll(ids)

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/me/episodes" })
  }

  @Test("Set chunked helper")
  func setChunking() {
    let set = Set(1...10)
    let chunks = set.chunked(into: 3)

    #expect(chunks.count == 4)
    #expect(chunks.reduce(0) { $0 + $1.count } == 10)
    #expect(chunks.allSatisfy { $0.count <= 3 })
  }

  @Test
  func albumsSaveAllDeduplicatesIDs() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)

    try await client.albums.saveAll(["album1", "album1", "album2"])

    let requests = await http.requests
    #expect(requests.count == 1)
    #expect(decodedIDs(from: requests.first) == Set(["album1", "album2"]))
  }

  @Test
  func tracksSaveAllSkipsEmptyInput() async throws {
    let (client, http) = makeUserAuthClient()
    try await client.tracks.saveAll([])
    let requests = await http.requests
    #expect(requests.isEmpty)
  }

  @Test
  func episodesSaveAllDeduplicatesIDs() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(data: Data(), statusCode: 200)

    try await client.episodes.saveAll(["episode1", "episode1", "episode2"])

    let requests = await http.requests
    #expect(requests.count == 1)
    #expect(decodedIDs(from: requests.first) == Set(["episode1", "episode2"]))
  }

  @Test
  func showsRemoveAllPropagatesErrors() async {
    let (client, http) = makeUserAuthClient()
    await http.addError(TestError.general("boom"))
    await http.addMockResponse(data: Data(), statusCode: 200)

    await #expect(throws: TestError.general("boom")) {
      try await client.shows.removeAll(["show1", "show2"])
    }

    let requests = await http.requests
    #expect(requests.count == 1)
  }
}

// MARK: - Test Helpers

extension Set {
  fileprivate func chunked(into size: Int) -> [Set<Element>] {
    let array = Array(self)
    return stride(from: 0, to: array.count, by: size).map {
      Set(array[$0..<Swift.min($0 + size, array.count)])
    }
  }
}

private func decodedIDs(from request: URLRequest?) -> Set<String>? {
  guard
    let body = request?.httpBody,
    let payload = try? JSONDecoder().decode(IDsBody.self, from: body)
  else {
    return nil
  }
  return payload.ids
}

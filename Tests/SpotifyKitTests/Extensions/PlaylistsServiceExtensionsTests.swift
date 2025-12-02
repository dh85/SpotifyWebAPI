import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("PlaylistsService Extensions Tests")
@MainActor
struct PlaylistsServiceExtensionsTests {

  @Test("addTracks chunks into batches of 100")
  func addTracksChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 201)
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 201)
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap3"}"#.data(using: .utf8)!, statusCode: 201)

    let uris = (1...250).map { "spotify:track:\($0)" }
    try await client.playlists.addTracks(uris, to: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 3)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/playlists/playlist123/tracks" })
  }

  @Test("addTracks handles single batch")
  func addTracksSingleBatch() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 201)

    let uris = (1...50).map { "spotify:track:\($0)" }
    try await client.playlists.addTracks(uris, to: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 1)
  }

  @Test("removeTracks chunks into batches of 100")
  func removeTracksChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 200)
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 200)

    let uris = (1...150).map { "spotify:track:\($0)" }
    try await client.playlists.removeTracks(uris, from: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 2)
    #expect(requests.allSatisfy { $0.url?.path == "/v1/playlists/playlist123/tracks" })
  }

  @Test("Array chunked helper")
  func arrayChunking() {
    let array = Array(1...10)
    let chunks = array.chunked(into: 3)

    #expect(chunks.count == 4)
    #expect(chunks[0] == [1, 2, 3])
    #expect(chunks[1] == [4, 5, 6])
    #expect(chunks[2] == [7, 8, 9])
    #expect(chunks[3] == [10])
  }

  @Test
  func addTracksSkipsEmptyCollections() async throws {
    let (client, http) = makeUserAuthClient()
    try await client.playlists.addTracks([], to: "playlist123")
    let requests = await http.requests
    #expect(requests.isEmpty)
  }

  @Test
  func removeTracksSkipsEmptyCollections() async throws {
    let (client, http) = makeUserAuthClient()
    try await client.playlists.removeTracks([], from: "playlist123")
    let requests = await http.requests
    #expect(requests.isEmpty)
  }

  @Test
  func addTracksPreservesOrderAcrossBatches() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 201)
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 201)

    let uris = (1...150).map { "spotify:track:\($0)" }
    try await client.playlists.addTracks(uris, to: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 2)

    let firstBody = decodeAddBody(requests[0])
    let secondBody = decodeAddBody(requests[1])
    #expect(firstBody == Array(uris.prefix(100)))
    #expect(secondBody == Array(uris.suffix(50)))
  }

  @Test
  func removeTracksMaintainsOrderAndChunking() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 200)
    await http.addMockResponse(
      data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 200)

    let uris = (1...120).map { "spotify:track:\($0)" }
    try await client.playlists.removeTracks(uris, from: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 2)

    let first = decodeRemoveBody(requests[0])
    let second = decodeRemoveBody(requests[1])
    #expect(first == Array(uris.prefix(100)))
    #expect(second == Array(uris.suffix(20)))
  }

  @Test
  func addTracksRetriesAfterRateLimit() async throws {
    let configuration = SpotifyClientConfiguration(maxRateLimitRetries: 2)
    let (client, http) = makeUserAuthClient(configuration: configuration)
    let successData = #"{"snapshot_id":"snap"}"#.data(using: .utf8)!
    await http.addMockResponse(
      statusCode: 429,
      headers: ["Retry-After": "0"]
    )
    await http.addMockResponse(data: successData, statusCode: 201)
    await http.addMockResponse(data: successData, statusCode: 201)

    let uris = (1...120).map { "spotify:track:\($0)" }
    try await client.playlists.addTracks(uris, to: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 3)  // 2 for first chunk (retry) + 1 for second chunk
  }

  @Test
  func removeTracksRetriesAfterRateLimit() async throws {
    let configuration = SpotifyClientConfiguration(maxRateLimitRetries: 2)
    let (client, http) = makeUserAuthClient(configuration: configuration)
    let successData = #"{"snapshot_id":"snap"}"#.data(using: .utf8)!
    await http.addMockResponse(
      statusCode: 429,
      headers: ["Retry-After": "0"]
    )
    await http.addMockResponse(data: successData, statusCode: 200)
    await http.addMockResponse(data: successData, statusCode: 200)

    let uris = (1...120).map { "spotify:track:\($0)" }
    try await client.playlists.removeTracks(uris, from: "playlist123")

    let requests = await http.requests
    #expect(requests.count == 3)
  }

  @Test
  func addTracksCancellationStopsFurtherRequests() async throws {
    let (client, http) = makeUserAuthClient()
    let success = #"{"snapshot_id":"snap"}"#.data(using: .utf8)!
    await http.addMockResponse(data: success, statusCode: 201, delay: .milliseconds(200))
    await http.addMockResponse(data: success, statusCode: 201)

    let uris = (1...150).map { "spotify:track:\($0)" }
    let task = Task {
      try await client.playlists.addTracks(uris, to: "playlist123")
    }

    try await Task.sleep(for: .milliseconds(50))
    task.cancel()

    await #expect(throws: CancellationError.self) {
      _ = try await task.value
    }
    #expect(await http.requests.count == 1)
  }

  @Test
  func removeTracksCancellationStopsFurtherRequests() async throws {
    let (client, http) = makeUserAuthClient()
    let success = #"{"snapshot_id":"snap"}"#.data(using: .utf8)!
    await http.addMockResponse(data: success, statusCode: 200, delay: .milliseconds(200))
    await http.addMockResponse(data: success, statusCode: 200)

    let uris = (1...150).map { "spotify:track:\($0)" }
    let task = Task {
      try await client.playlists.removeTracks(uris, from: "playlist123")
    }

    try await Task.sleep(for: .milliseconds(50))
    task.cancel()

    await #expect(throws: CancellationError.self) {
      _ = try await task.value
    }
    #expect(await http.requests.count == 1)
  }
}

// MARK: - Test Helpers

extension Array {
  fileprivate func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

private func decodeAddBody(_ request: URLRequest?) -> [String]? {
  guard
    let data = request?.httpBody,
    let body = try? JSONDecoder().decode(AddBody.self, from: data)
  else { return nil }
  return body.uris
}

private func decodeRemoveBody(_ request: URLRequest?) -> [String]? {
  guard
    let data = request?.httpBody,
    let body = try? JSONDecoder().decode(RemoveBody.self, from: data)
  else { return nil }
  return body.tracks?.map { $0.uri }
}

private struct AddBody: Decodable { let uris: [String] }
private struct RemoveBody: Decodable {
  struct Track: Decodable { let uri: String }
  let tracks: [Track]?
}

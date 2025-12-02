import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct PerformanceTests {

  @Test(.timeLimit(.minutes(1)))
  func decodingLargePagePerformance() async throws {
    let data = try TestDataLoader.load("playlists_user")
    let iterations = 100

    let duration = try measureAverageTime(iterations: iterations) {
      let _: Page<SimplifiedPlaylist> = try decodeModel(from: data)
    }

    #expect(duration < 0.01, "Average decode time: \(duration)s")
  }

  @Test(.timeLimit(.minutes(1)))
  @MainActor
  func concurrentRequestsPerformance() async throws {
    let (client, http) = makeUserAuthClient()

    for _ in 0..<10 {
      let data = try TestDataLoader.load("current_user_profile")
      await http.addMockResponse(
        data: data,
        statusCode: 200,
        url: URL(string: "https://api.spotify.com/v1/me")!
      )
    }

    let duration = try await measureDuration {
      try await withThrowingTaskGroup(of: CurrentUserProfile.self) { group in
        for _ in 0..<10 {
          group.addTask {
            try await client.users.me()
          }
        }

        var count = 0
        for try await _ in group {
          count += 1
        }

        #expect(count == 10)
      }
    }

    #expect(duration < 0.5, "Duration: \(duration)s")
  }

  @Test(.timeLimit(.minutes(1)))
  func encodingLargeModelPerformance() throws {
    let album = Album.perfExample
    let duration = try measureAverageTime(iterations: 100) {
      _ = try encodeModel(album)
    }

    #expect(duration < 0.01, "Average encode time: \(duration)s")
  }

  @Test(.timeLimit(.minutes(1)))
  @MainActor
  func collectAllPagesPerformance() async throws {
    let (client, _) = makeUserAuthClient()
    let playlists = (0..<500).map { SpotifyTestFixtures.simplifiedPlaylist(id: "id-\($0)") }
    let basePage = SpotifyTestFixtures.playlistsPage(
      playlists: playlists,
      limit: 50,
      total: 500
    )

    let duration = try await measureDuration {
      let items: [SimplifiedPlaylist] = try await client.collectAllPages(
        pageSize: 50,
        maxItems: 500
      ) { _, offset in
        let slice = Array(playlists.dropFirst(offset).prefix(50))
        let nextOffset = offset + slice.count
        let nextURL =
          nextOffset < basePage.total
          ? URL(string: "\(basePage.href.absoluteString)?offset=\(nextOffset)&limit=50")
          : nil
        return Page(
          href: basePage.href,
          items: slice,
          limit: slice.count,
          next: nextURL,
          offset: offset,
          previous: nil,
          total: basePage.total
        )
      }
      #expect(items.count == 500)
    }

    #expect(duration < 2.0, "collectAllPages duration: \(duration)s")
  }
}

// MARK: - Helpers

private func measureDuration(
  _ operation: @escaping @Sendable () async throws -> Void
) async throws -> TimeInterval {
  let clock = ContinuousClock()
  let start = clock.now
  try await operation()
  let duration = clock.now - start
  return duration.toTimeInterval()
}

private func measureAverageTime(
  iterations: Int,
  operation: () throws -> Void
) throws -> TimeInterval {
  let clock = ContinuousClock()
  let start = clock.now
  for _ in 0..<iterations {
    try operation()
  }
  let duration = clock.now - start
  return duration.toTimeInterval() / Double(iterations)
}

extension Duration {
  fileprivate func toTimeInterval() -> TimeInterval {
    Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
  }
}

extension Album {
  fileprivate static let perfExample = Album.fullExample
}

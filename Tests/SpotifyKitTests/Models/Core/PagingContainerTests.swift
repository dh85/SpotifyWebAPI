import Foundation
import Testing

@testable import SpotifyKit

private struct TestPagingContainer: PagingContainer {
  typealias Item = Int
  let href: URL
  let items: [Int]
  let limit: Int
  let next: URL?
}

private struct TestOffsetPagingContainer: OffsetPagingContainer {
  typealias Item = String
  let href: URL
  let items: [String]
  let limit: Int
  let next: URL?
  let offset: Int
  let previous: URL?
  let total: Int
}

@Suite
struct PagingContainerTests {

  @Test
  func hasMoreReflectsNextLink() async throws {
    let baseURL = URL(string: "https://api.spotify.com/v1/test")!
    let containerWithNext = TestPagingContainer(
      href: baseURL,
      items: [1, 2, 3],
      limit: 3,
      next: baseURL.appending(path: "next")
    )
    let containerWithoutNext = TestPagingContainer(
      href: baseURL,
      items: [4, 5],
      limit: 2,
      next: nil
    )

    #expect(containerWithNext.hasMore == true)
    #expect(containerWithoutNext.hasMore == false)
  }

  @Test
  func hasPreviousReflectsPreviousLink() async throws {
    let baseURL = URL(string: "https://api.spotify.com/v1/test")!
    let containerWithPrev = TestOffsetPagingContainer(
      href: baseURL,
      items: ["a", "b"],
      limit: 2,
      next: baseURL.appending(path: "next"),
      offset: 2,
      previous: baseURL.appending(path: "prev"),
      total: 10
    )
    let containerWithoutPrev = TestOffsetPagingContainer(
      href: baseURL,
      items: ["c"],
      limit: 1,
      next: nil,
      offset: 0,
      previous: nil,
      total: 1
    )

    #expect(containerWithPrev.hasPrevious == true)
    #expect(containerWithoutPrev.hasPrevious == false)
  }
}

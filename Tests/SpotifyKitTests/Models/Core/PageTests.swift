import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PageTests {

  @Test
  func encodesCorrectly() throws {
    let page = Page(
      href: URL(string: "https://api.spotify.com/v1/test")!,
      items: ["item1"],
      limit: 1,
      next: URL(string: "https://api.spotify.com/v1/test?offset=1"),
      offset: 0,
      previous: nil,
      total: 5
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(page)
    let decoded: Page<String> = try JSONDecoder().decode(Page.self, from: data)

    #expect(decoded == page)
  }
}

import Foundation
import Testing

@testable import SpotifyKit

@Suite struct CursorBasedPageTests {

  @Test
  func decodesWithAllFields() throws {
    let json = """
      {
          "href": "https://api.spotify.com/v1/me/following?type=artist",
          "items": [
              {
                  "id": "artist1",
                  "name": "Artist 1",
                  "type": "artist",
                  "uri": "spotify:artist:artist1",
                  "href": "https://api.spotify.com/v1/artists/artist1",
                  "genres": [],
                  "popularity": 80
              }
          ],
          "limit": 20,
          "next": "https://api.spotify.com/v1/me/following?type=artist&after=cursor123",
          "cursors": {
              "after": "cursor123",
              "before": "cursor456"
          }
      }
      """
    let data = json.data(using: .utf8)!
    let page: CursorBasedPage<Artist> = try decodeModel(from: data)

    #expect(page.href.absoluteString == "https://api.spotify.com/v1/me/following?type=artist")
    #expect(page.items.count == 1)
    #expect(page.items.first?.name == "Artist 1")
    #expect(page.limit == 20)
    #expect(page.next?.absoluteString.contains("after=cursor123") == true)
    #expect(page.cursors.after == "cursor123")
    #expect(page.cursors.before == "cursor456")
  }

  @Test
  func decodesWithNullCursors() throws {
    let json = """
      {
          "href": "https://api.spotify.com/v1/me/following?type=artist",
          "items": [],
          "limit": 20,
          "next": null,
          "cursors": {
              "after": null,
              "before": null
          }
      }
      """
    let data = json.data(using: .utf8)!
    let page: CursorBasedPage<Artist> = try decodeModel(from: data)

    #expect(page.items.isEmpty)
    #expect(page.next == nil)
    #expect(page.cursors.after == nil)
    #expect(page.cursors.before == nil)
  }
}

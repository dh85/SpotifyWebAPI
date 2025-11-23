import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PagingTests {

    @Test
    func decodes_CursorBasedPage_withFullData() async throws {
        // Arrange
        let testData = try TestDataLoader.load("cursor_page_artists_full.json")

        // Act
        let page: CursorBasedPage<Artist> = try decodeModel(from: testData)

        // Assert
        #expect(page.limit == 2)
        #expect(page.items.count == 1)
        #expect(
            page.next?.absoluteString.contains("after=cursor_after_id") == true
        )

        // Assert nested items
        let artist = try #require(page.items.first)
        #expect(artist.name == "Artist One")
        #expect(artist.popularity == 80)

        // Assert nested Cursors struct
        #expect(page.cursors.after == "cursor_after_id")
        #expect(page.cursors.before == "cursor_before_id")
    }

    @Test
    func decodes_CursorBasedPage_withEmptyData() async throws {
        // Arrange
        let testData = try TestDataLoader.load("cursor_page_artists_empty.json")

        // Act
        let page: CursorBasedPage<Artist> = try decodeModel(from: testData)

        // Assert
        #expect(page.limit == 2)
        #expect(page.items.isEmpty == true)
        #expect(page.next == nil)

        // Assert nested Cursors struct
        #expect(page.cursors.after == nil)
        #expect(page.cursors.before == nil)
    }
}

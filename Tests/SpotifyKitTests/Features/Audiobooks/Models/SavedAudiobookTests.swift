import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SavedAudiobookTests {

  @Test
  func decodesSavedAudiobookPage() throws {
    let data = try TestDataLoader.load("audiobooks_saved")
    let page: Page<SavedAudiobook> = try decodeModel(from: data)

    #expect(page.total == 1)
    let item = try #require(page.items.first)
    #expect(item.audiobook.id == "ab1")
    #expect(item.audiobook.name == "Saved Audiobook Title")
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    #expect(item.addedAt == formatter.date(from: "2023-01-01T12:00:00Z"))
  }

  @Test
  func contentPropertyReturnsAudiobook() throws {
    let data = try TestDataLoader.load("audiobooks_saved")
    let page: Page<SavedAudiobook> = try decodeModel(from: data)
    let saved = try #require(page.items.first)

    #expect(saved.content.id == saved.audiobook.id)
    #expect(saved.content.name == saved.audiobook.name)
  }
}

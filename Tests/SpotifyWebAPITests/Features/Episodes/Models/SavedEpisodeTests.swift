import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedEpisodeTests {

    @Test
    func decodesSavedEpisodesPage() throws {
        let data = try TestDataLoader.load("episodes_saved")
        let page: Page<SavedEpisode> = try decodeModel(from: data)

        #expect(page.total == 1)
        let item = try #require(page.items.first)
        #expect(item.episode.id == "saved1")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        #expect(item.addedAt == formatter.date(from: "2024-01-01T00:00:00Z"))
    }
    
    @Test
    func contentPropertyReturnsEpisode() throws {
        let data = try TestDataLoader.load("episodes_saved")
        let page: Page<SavedEpisode> = try decodeModel(from: data)
        let saved = try #require(page.items.first)
        
        #expect(saved.content.id == saved.episode.id)
        #expect(saved.content.name == saved.episode.name)
    }
}

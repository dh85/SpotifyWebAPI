import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedTrackTests {

    @Test
    func decodesSavedTracksPage() throws {
        let data = try TestDataLoader.load("tracks_saved")
        let page: Page<SavedTrack> = try decodeModel(from: data)

        #expect(page.items.count == 1)
        let saved = try #require(page.items.first)
        #expect(saved.track.id == "track1")
        #expect(saved.track.name == "Test Track")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        #expect(saved.addedAt == formatter.date(from: "2024-01-01T12:00:00Z"))
    }
}

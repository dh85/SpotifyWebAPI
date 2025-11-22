import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlayHistoryItemTests {

    @Test
    func decodesHistoryItemFixture() throws {
        let data = try TestDataLoader.load("play_history_item")
        let item: PlayHistoryItem = try decodeModel(from: data)

        #expect(item.track.id == "track_1")
        #expect(item.context?.type == "playlist")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        #expect(item.playedAt == formatter.date(from: "2023-11-15T10:00:00Z"))
    }
}

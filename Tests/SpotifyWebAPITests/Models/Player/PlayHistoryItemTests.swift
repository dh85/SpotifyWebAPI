import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlayHistoryItemTests {

    @Test
    func decodes_PlayHistoryItem_Correctly() throws {
        // Arrange
        let testData = try TestDataLoader.load("play_history_item.json")

        // Act
        // We use decodeWithISO8601 because 'played_at' is an ISO string
        // and keys are snake_case.
        let item: PlayHistoryItem = try decodeModel(from: testData)

        // Assert - Track
        #expect(item.track.name == "History Track")
        #expect(item.track.artists.first?.name == "History Artist")

        // Assert - Context
        #expect(item.context?.type == "playlist")
        #expect(item.context?.uri == "spotify:playlist:playlist_history")

        // Assert - Played At
        // 2023-11-15T10:00:00Z is 1700042400 seconds since 1970
        #expect(item.playedAt.timeIntervalSince1970 == 1_700_042_400)
    }

    @Test
    func decodes_PlayHistoryItem_withNullContext() throws {
        // Arrange
        // Minimal JSON with null context - must include required album fields
        let json = """
            {
                "track": {
                    "id": "track_1",
                    "name": "Track",
                    "duration_ms": 0,
                    "explicit": false,
                    "uri": "u",
                    "href": "h",
                    "type": "track",
                    "disc_number": 1,
                    "track_number": 1,
                    "popularity": 50,
                    "is_local": false,
                    "external_ids": {"isrc": "US123"},
                    "external_urls": {},
                    "artists": [],
                    "album": { 
                        "id": "a", 
                        "name": "A", 
                        "images": [], 
                        "uri": "u", 
                        "href": "h", 
                        "external_urls": {},
                        "album_type": "album",
                        "total_tracks": 10,
                        "available_markets": [],
                        "release_date": "2024-01-01",
                        "release_date_precision": "day",
                        "type": "album",
                        "album_group": "album",
                        "artists": []
                    }
                },
                "played_at": "2023-01-01T00:00:00Z",
                "context": null
            }
            """
        let data = json.data(using: .utf8)!

        // Act
        let item: PlayHistoryItem = try decodeModel(from: data)

        // Assert
        #expect(item.context == nil)
        #expect(item.track.name == "Track")
    }
}

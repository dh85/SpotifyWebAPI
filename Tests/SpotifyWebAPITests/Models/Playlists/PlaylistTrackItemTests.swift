import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTrackItemTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "added_at": "2024-01-01T12:00:00Z",
                "added_by": {
                    "id": "user123",
                    "type": "user",
                    "uri": "spotify:user:user123",
                    "display_name": "Test User",
                    "href": "https://api.spotify.com/v1/users/user123",
                    "external_urls": {
                        "spotify": "https://open.spotify.com/user/user123"
                    }
                },
                "is_local": false,
                "track": {
                    "id": "track1",
                    "name": "Test Track",
                    "duration_ms": 180000,
                    "explicit": false,
                    "href": "https://api.spotify.com/v1/tracks/track1",
                    "uri": "spotify:track:track1",
                    "type": "track",
                    "disc_number": 1,
                    "track_number": 1,
                    "popularity": 50,
                    "is_local": false,
                    "external_ids": {"isrc": "US123"},
                    "external_urls": {
                        "spotify": "https://open.spotify.com/track/track1"
                    },
                    "album": {
                        "id": "a",
                        "name": "A",
                        "album_type": "album",
                        "total_tracks": 1,
                        "available_markets": [],
                        "external_urls": {},
                        "href": "https://api.spotify.com/v1/albums/a",
                        "images": [],
                        "release_date": "2024-01-01",
                        "release_date_precision": "day",
                        "type": "album",
                        "uri": "spotify:album:a",
                        "artists": []
                    },
                    "artists": []
                }
            }
            """
        let data = json.data(using: .utf8)!
        let item: PlaylistTrackItem = try decodeModel(from: data)

        #expect(item.addedAt != nil)
        #expect(item.addedBy?.id == "user123")
        #expect(item.isLocal == false)
        #expect(item.track != nil)
    }

    @Test
    func decodesWithMinimalFields() throws {
        let json = """
            {
                "is_local": true
            }
            """
        let data = json.data(using: .utf8)!
        let item: PlaylistTrackItem = try decodeModel(from: data)

        #expect(item.addedAt == nil)
        #expect(item.addedBy == nil)
        #expect(item.isLocal == true)
        #expect(item.track == nil)
    }

    @Test
    func decodesWithNullTrack() throws {
        let json = """
            {
                "added_at": "2024-01-01T12:00:00Z",
                "is_local": false,
                "track": null
            }
            """
        let data = json.data(using: .utf8)!
        let item: PlaylistTrackItem = try decodeModel(from: data)

        #expect(item.addedAt != nil)
        #expect(item.isLocal == false)
        #expect(item.track == nil)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "is_local": false,
                "added_at": "2024-01-01T12:00:00Z"
            }
            """
        let data = json.data(using: .utf8)!
        let item1: PlaylistTrackItem = try decodeModel(from: data)
        let item2: PlaylistTrackItem = try decodeModel(from: data)

        #expect(item1 == item2)
    }
}

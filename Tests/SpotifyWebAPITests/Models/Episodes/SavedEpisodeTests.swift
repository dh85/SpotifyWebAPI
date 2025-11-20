import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedEpisodeTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "added_at": "2024-01-15T10:30:00Z",
                "episode": {
                    "description": "Test episode",
                    "html_description": "<p>Test episode</p>",
                    "duration_ms": 1800000,
                    "explicit": false,
                    "external_urls": {"spotify": "https://open.spotify.com/episode/test123"},
                    "href": "https://api.spotify.com/v1/episodes/test123",
                    "id": "test123",
                    "images": [],
                    "is_externally_hosted": false,
                    "languages": ["en"],
                    "name": "Test Episode",
                    "release_date": "2024-01-01",
                    "release_date_precision": "day",
                    "type": "episode",
                    "uri": "spotify:episode:test123",
                    "show": {
                        "available_markets": [],
                        "copyrights": [],
                        "description": "Show",
                        "html_description": "Show",
                        "explicit": false,
                        "external_urls": {},
                        "href": "https://api.spotify.com/v1/shows/show123",
                        "id": "show123",
                        "images": [],
                        "is_externally_hosted": false,
                        "languages": ["en"],
                        "media_type": "audio",
                        "name": "Show",
                        "publisher": "Pub",
                        "type": "show",
                        "uri": "spotify:show:show123",
                        "total_episodes": 10
                    }
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved: SavedEpisode = try decodeModel(from: data)

        #expect(saved.episode.id == "test123")
        #expect(saved.addedAt.timeIntervalSince1970 > 0)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "added_at": "2024-01-01T00:00:00Z",
                "episode": {
                    "description": "Eq",
                    "html_description": "Eq",
                    "duration_ms": 1000,
                    "explicit": false,
                    "external_urls": {},
                    "href": "https://api.spotify.com/v1/episodes/eq123",
                    "id": "eq123",
                    "images": [],
                    "is_externally_hosted": false,
                    "languages": ["en"],
                    "name": "Eq",
                    "release_date": "2024",
                    "release_date_precision": "year",
                    "type": "episode",
                    "uri": "spotify:episode:eq123",
                    "show": {
                        "available_markets": [],
                        "copyrights": [],
                        "description": "S",
                        "html_description": "S",
                        "explicit": false,
                        "external_urls": {},
                        "href": "https://api.spotify.com/v1/shows/s123",
                        "id": "s123",
                        "images": [],
                        "is_externally_hosted": false,
                        "languages": ["en"],
                        "media_type": "audio",
                        "name": "S",
                        "publisher": "P",
                        "type": "show",
                        "uri": "spotify:show:s123",
                        "total_episodes": 1
                    }
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved1: SavedEpisode = try decodeModel(from: data)
        let saved2: SavedEpisode = try decodeModel(from: data)

        #expect(saved1 == saved2)
    }
}

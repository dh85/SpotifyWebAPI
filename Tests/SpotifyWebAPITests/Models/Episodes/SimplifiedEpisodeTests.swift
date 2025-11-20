import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedEpisodeTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "description": "Episode description",
                "html_description": "<p>Episode description</p>",
                "duration_ms": 1800000,
                "explicit": false,
                "external_urls": {"spotify": "https://open.spotify.com/episode/test123"},
                "href": "https://api.spotify.com/v1/episodes/test123",
                "id": "test123",
                "images": [{"url": "https://example.com/image.jpg", "height": 640, "width": 640}],
                "is_externally_hosted": false,
                "is_playable": true,
                "languages": ["en"],
                "name": "Test Episode",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "resume_point": {"fully_played": false, "resume_position_ms": 1000},
                "type": "episode",
                "uri": "spotify:episode:test123",
                "restrictions": {"reason": "market"}
            }
            """
        let data = json.data(using: .utf8)!
        let episode: SimplifiedEpisode = try decodeModel(from: data)

        #expect(episode.id == "test123")
        #expect(episode.name == "Test Episode")
        #expect(episode.durationMs == 1_800_000)
        #expect(episode.explicit == false)
        #expect(episode.isExternallyHosted == false)
        #expect(episode.isPlayable == true)
        #expect(episode.resumePoint?.fullyPlayed == false)
        #expect(episode.restrictions?.reason == .market)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "description": "Minimal",
                "html_description": "<p>Minimal</p>",
                "duration_ms": 1000,
                "explicit": true,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/episodes/min123",
                "id": "min123",
                "images": [],
                "is_externally_hosted": true,
                "is_playable": false,
                "languages": ["en"],
                "name": "Minimal",
                "release_date": "2024",
                "release_date_precision": "year",
                "type": "episode",
                "uri": "spotify:episode:min123"
            }
            """
        let data = json.data(using: .utf8)!
        let episode: SimplifiedEpisode = try decodeModel(from: data)

        #expect(episode.id == "min123")
        #expect(episode.resumePoint == nil)
        #expect(episode.restrictions == nil)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "description": "Equal",
                "html_description": "<p>Equal</p>",
                "duration_ms": 2000,
                "explicit": false,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/episodes/eq123",
                "id": "eq123",
                "images": [],
                "is_externally_hosted": false,
                "is_playable": true,
                "languages": ["en"],
                "name": "Equal",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "type": "episode",
                "uri": "spotify:episode:eq123"
            }
            """
        let data = json.data(using: .utf8)!
        let episode1: SimplifiedEpisode = try decodeModel(from: data)
        let episode2: SimplifiedEpisode = try decodeModel(from: data)

        #expect(episode1 == episode2)
    }
}

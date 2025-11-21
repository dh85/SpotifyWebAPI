import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("UserQueue Tests")
struct UserQueueTests {

    @Test("Decodes user queue with tracks")
    func decodesUserQueueWithTracks() throws {
        let data = try TestDataLoader.load("queue")
        let queue: UserQueue = try decodeModel(from: data)

        #expect(queue.currentlyPlaying != nil)
        if case .track(let track) = queue.currentlyPlaying {
            #expect(track.name == "Currently Playing Track")
        } else {
            Issue.record("Expected track")
        }

        #expect(queue.queue.count == 2)
        if case .track(let track) = queue.queue[0] {
            #expect(track.name == "Next Track 1")
        } else {
            Issue.record("Expected track")
        }
    }

    @Test("Decodes user queue with episode")
    func decodesUserQueueWithEpisode() throws {
        let json = """
        {
            "currently_playing": null,
            "queue": [
                {
                    "id": "episode1",
                    "name": "Test Episode",
                    "type": "episode",
                    "uri": "spotify:episode:episode1",
                    "href": "https://api.spotify.com/v1/episodes/episode1",
                    "duration_ms": 1800000,
                    "explicit": false,
                    "description": "Test episode",
                    "html_description": "Test episode",
                    "languages": ["en"],
                    "release_date": "2024-01-01",
                    "release_date_precision": "day",
                    "is_externally_hosted": false,
                    "is_playable": true,
                    "external_urls": {
                        "spotify": "https://open.spotify.com/episode/episode1"
                    },
                    "images": [],
                    "show": {
                        "id": "show1",
                        "name": "Test Show",
                        "type": "show",
                        "uri": "spotify:show:show1",
                        "href": "https://api.spotify.com/v1/shows/show1",
                        "publisher": "Test Publisher",
                        "description": "Test show",
                        "explicit": false,
                        "is_externally_hosted": false,
                        "languages": ["en"],
                        "media_type": "audio",
                        "total_episodes": 10,
                        "external_urls": {
                            "spotify": "https://open.spotify.com/show/show1"
                        },
                        "images": []
                    }
                }
            ]
        }
        """
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let queue = try decoder.decode(UserQueue.self, from: json.data(using: .utf8)!)
        
        #expect(queue.currentlyPlaying == nil)
        #expect(queue.queue.count == 1)
        if case .episode(let episode) = queue.queue[0] {
            #expect(episode.name == "Test Episode")
        } else {
            Issue.record("Expected episode")
        }
    }

    @Test("Throws error for unknown playable item type")
    func throwsErrorForUnknownType() throws {
        let json = """
            {
                "currently_playing": null,
                "queue": [
                    {
                        "id": "unknown1",
                        "name": "Unknown Item",
                        "type": "advertisement",
                        "uri": "spotify:ad:unknown1"
                    }
                ]
            }
            """

        #expect(throws: DecodingError.self) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            _ = try decoder.decode(UserQueue.self, from: json.data(using: .utf8)!)
        }
    }
}

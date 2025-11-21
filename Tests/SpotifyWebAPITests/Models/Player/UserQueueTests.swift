import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("UserQueue Tests")
struct UserQueueTests {
    
    @Test("Decodes queue with currently playing track")
    func decodesQueueWithCurrentlyPlayingTrack() throws {
        let json = """
        {
            "currently_playing": {
                "id": "track1",
                "name": "Test Track",
                "type": "track",
                "duration_ms": 180000,
                "explicit": false,
                "href": "https://api.spotify.com/v1/tracks/track1",
                "uri": "spotify:track:track1",
                "disc_number": 1,
                "track_number": 1,
                "popularity": 75,
                "is_local": false,
                "external_ids": {"isrc": "US123"},
                "external_urls": {"spotify": "https://open.spotify.com/track/track1"},
                "artists": [{
                    "id": "artist1",
                    "name": "Artist",
                    "type": "artist",
                    "href": "https://api.spotify.com/v1/artists/artist1",
                    "uri": "spotify:artist:artist1",
                    "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"}
                }],
                "album": {
                    "id": "album1",
                    "name": "Album",
                    "href": "https://api.spotify.com/v1/albums/album1",
                    "uri": "spotify:album:album1",
                    "images": [],
                    "external_urls": {"spotify": "https://open.spotify.com/album/album1"},
                    "album_type": "album",
                    "total_tracks": 10,
                    "available_markets": ["US"],
                    "release_date": "2024-01-01",
                    "release_date_precision": "day",
                    "type": "album",
                    "artists": [{
                        "id": "artist1",
                        "name": "Artist",
                        "href": "https://api.spotify.com/v1/artists/artist1",
                        "uri": "spotify:artist:artist1",
                        "type": "artist",
                        "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"}
                    }]
                }
            },
            "queue": []
        }
        """.data(using: .utf8)!
        
        let queue: UserQueue = try decodeModel(from: json)
        
        #expect(queue.currentlyPlaying != nil)
        if case .track(let track) = queue.currentlyPlaying {
            #expect(track.name == "Test Track")
        } else {
            Issue.record("Expected track case")
        }
        #expect(queue.queue.isEmpty)
    }
    
    @Test("Decodes queue with currently playing episode")
    func decodesQueueWithCurrentlyPlayingEpisode() throws {
        let json = """
        {
            "currently_playing": {
                "id": "episode1",
                "name": "Test Episode",
                "type": "episode",
                "duration_ms": 3600000,
                "explicit": false,
                "href": "https://api.spotify.com/v1/episodes/episode1",
                "uri": "spotify:episode:episode1",
                "description": "Test description",
                "html_description": "<p>Test description</p>",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "language": "en",
                "languages": ["en"],
                "is_externally_hosted": false,
                "is_playable": true,
                "external_urls": {"spotify": "https://open.spotify.com/episode/episode1"},
                "images": [],
                "show": {
                    "id": "show1",
                    "name": "Test Show",
                    "publisher": "Publisher",
                    "type": "show",
                    "href": "https://api.spotify.com/v1/shows/show1",
                    "uri": "spotify:show:show1",
                    "description": "Show description",
                    "html_description": "<p>Show description</p>",
                    "explicit": false,
                    "is_externally_hosted": false,
                    "languages": ["en"],
                    "media_type": "audio",
                    "total_episodes": 100,
                    "external_urls": {"spotify": "https://open.spotify.com/show/show1"},
                    "images": [],
                    "available_markets": ["US"]
                }
            },
            "queue": []
        }
        """.data(using: .utf8)!
        
        let queue: UserQueue = try decodeModel(from: json)
        
        #expect(queue.currentlyPlaying != nil)
        if case .episode(let episode) = queue.currentlyPlaying {
            #expect(episode.name == "Test Episode")
        } else {
            Issue.record("Expected episode case")
        }
        #expect(queue.queue.isEmpty)
    }
    
    @Test("Decodes queue with nil currently playing")
    func decodesQueueWithNilCurrentlyPlaying() throws {
        let json = """
        {
            "currently_playing": null,
            "queue": []
        }
        """.data(using: .utf8)!
        
        let queue: UserQueue = try decodeModel(from: json)
        
        #expect(queue.currentlyPlaying == nil)
        #expect(queue.queue.isEmpty)
    }
    
    @Test("Decodes queue with multiple tracks")
    func decodesQueueWithMultipleTracks() throws {
        let testData = try TestDataLoader.load("queue.json")
        let queue: UserQueue = try decodeModel(from: testData)
        
        #expect(queue.queue.count == 2)
        if case .track(let track) = queue.queue[0] {
            #expect(track.name == "Next Track 1")
        } else {
            Issue.record("Expected track case")
        }
    }
    
    @Test("Throws error for unknown playable item type")
    func throwsErrorForUnknownType() throws {
        let json = """
        {
            "currently_playing": null,
            "queue": [{
                "id": "unknown1",
                "name": "Unknown Item",
                "type": "unknown_type"
            }]
        }
        """.data(using: .utf8)!
        
        #expect(throws: DecodingError.self) {
            let _: UserQueue = try decodeModel(from: json)
        }
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() throws {
        let testData = try TestDataLoader.load("queue.json")
        let queue1: UserQueue = try decodeModel(from: testData)
        let queue2: UserQueue = try decodeModel(from: testData)
        
        #expect(queue1 == queue2)
    }
}

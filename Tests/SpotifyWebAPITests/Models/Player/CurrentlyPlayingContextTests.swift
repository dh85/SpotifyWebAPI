import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("CurrentlyPlayingContext Tests")
struct CurrentlyPlayingContextTests {
    @Test("Decodes track with context")
    func decodesTrackWithContext() throws {
        let testData = try TestDataLoader.load("playback_context_track.json")
        let context: CurrentlyPlayingContext = try decodeModel(from: testData)
        
        #expect(context.context != nil)
        #expect(context.isPlaying == true)
        #expect(context.currentlyPlayingType == "track")
        #expect(context.progressMs == 123456)
        guard case .track(let track) = context.item else {
            Issue.record("Expected track item")
            return
        }
        #expect(track.name == "Mock Track Title")
    }
    
    @Test("Decodes without optional device fields")
    func decodesWithoutOptionalDeviceFields() throws {
        let json = """
        {
            "timestamp": 1600000000000,
            "progress_ms": 1000,
            "is_playing": true,
            "currently_playing_type": "track",
            "actions": {},
            "item": {
                "type": "track",
                "id": "t1",
                "name": "Track",
                "duration_ms": 180000,
                "explicit": false,
                "href": "h",
                "uri": "u",
                "disc_number": 1,
                "track_number": 1,
                "popularity": 50,
                "is_local": false,
                "external_ids": {"isrc": "US"},
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
                    "total_tracks": 1,
                    "available_markets": [],
                    "release_date": "2024-01-01",
                    "release_date_precision": "day",
                    "type": "album",
                    "album_group": "album",
                    "artists": []
                }
            }
        }
        """.data(using: .utf8)!
        
        let context: CurrentlyPlayingContext = try decodeModel(from: json)
        
        #expect(context.device == nil)
        #expect(context.repeatState == nil)
        #expect(context.shuffleState == nil)
        #expect(context.context == nil)
        #expect(context.isPlaying == true)
    }
    
    @Test("Decodes episode type")
    func decodesEpisodeType() throws {
        let testData = try TestDataLoader.load("playback_context_episode.json")
        let context: CurrentlyPlayingContext = try decodeModel(from: testData)
        
        #expect(context.currentlyPlayingType == "episode")
        guard case .episode(let episode) = context.item else {
            Issue.record("Expected episode item")
            return
        }
        #expect(episode.name == "Mock Episode Title")
    }
    
    @Test("Decodes ad type with nil item")
    func decodesAdTypeWithNilItem() throws {
        let json = """
        {
            "timestamp": 1600000000000,
            "progress_ms": 1000,
            "is_playing": true,
            "currently_playing_type": "ad",
            "actions": {},
            "item": null
        }
        """.data(using: .utf8)!
        
        let context: CurrentlyPlayingContext = try decodeModel(from: json)
        
        #expect(context.currentlyPlayingType == "ad")
        #expect(context.item == nil)
    }
    
    @Test("Timestamp converts correctly from milliseconds")
    func timestampConvertsCorrectlyFromMilliseconds() throws {
        let json = """
        {
            "timestamp": 1610000000000,
            "is_playing": false,
            "currently_playing_type": "unknown",
            "actions": {}
        }
        """.data(using: .utf8)!
        
        let context: CurrentlyPlayingContext = try decodeModel(from: json)
        
        #expect(context.timestamp.timeIntervalSince1970 == 1_610_000_000)
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() throws {
        let testData = try TestDataLoader.load("playback_context_track.json")
        
        let context1: CurrentlyPlayingContext = try decodeModel(from: testData)
        let context2: CurrentlyPlayingContext = try decodeModel(from: testData)
        
        #expect(context1 == context2)
    }
}

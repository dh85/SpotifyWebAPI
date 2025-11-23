import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaybackStateTests {
    
    @Test
    func decodesPlaybackStateWithTrack() throws {
        let data = try TestDataLoader.load("playback_state.json")
        let state: PlaybackState = try decodeModel(from: data)
        
        #expect(state.isPlaying == true)
        #expect(state.currentlyPlayingType == .track)
        
        if case .track(let track) = state.item {
            #expect(track.name == "Test Track")
        } else {
            Issue.record("Expected track item")
        }
    }
    
    @Test
    func decodesPlaybackStateWithEpisode() throws {
        // Create modified JSON with episode type
        let baseData = try TestDataLoader.load("playback_state.json")
        var json = try JSONSerialization.jsonObject(with: baseData) as! [String: Any]
        json["currently_playing_type"] = "episode"
        
        // Replace track with episode
        let episodeData = try TestDataLoader.load("episode_full.json")
        let episode = try JSONSerialization.jsonObject(with: episodeData)
        json["item"] = episode
        
        let data = try JSONSerialization.data(withJSONObject: json)
        let state: PlaybackState = try decodeModel(from: data)
        
        #expect(state.currentlyPlayingType == .episode)
        
        if case .episode(let episode) = state.item {
            #expect(episode.name == "Episode 1")
        } else {
            Issue.record("Expected episode item")
        }
    }
    
    @Test
    func decodesPlaybackStateWithAdTypeHasNilItem() throws {
        let json = """
        {
            "device": {
                "id": "device1",
                "is_active": true,
                "is_private_session": false,
                "is_restricted": false,
                "name": "Test Device",
                "type": "Computer",
                "volume_percent": 50,
                "supports_volume": true
            },
            "repeat_state": "off",
            "shuffle_state": false,
            "context": null,
            "timestamp": 1609459200000,
            "progress_ms": 30000,
            "is_playing": true,
            "currently_playing_type": "ad",
            "actions": {
                "interrupting_playback": false,
                "pausing": false,
                "resuming": false,
                "seeking": false,
                "skipping_next": false,
                "skipping_prev": false,
                "toggling_repeat_context": false,
                "toggling_shuffle": false,
                "toggling_repeat_track": false,
                "transferring_playback": false
            },
            "item": null
        }
        """
        
        let data = json.data(using: .utf8)!
        let state: PlaybackState = try decodeModel(from: data)
        
        #expect(state.isPlaying == true)
        #expect(state.currentlyPlayingType == .ad)
        #expect(state.item == nil)
    }
    
    @Test
    func decodesPlaybackStateWithUnknownTypeHasNilItem() throws {
        let json = """
        {
            "device": {
                "id": "device1",
                "is_active": true,
                "is_private_session": false,
                "is_restricted": false,
                "name": "Test Device",
                "type": "Computer",
                "volume_percent": 50,
                "supports_volume": true
            },
            "repeat_state": "off",
            "shuffle_state": false,
            "context": null,
            "timestamp": 1609459200000,
            "progress_ms": 30000,
            "is_playing": true,
            "currently_playing_type": "unknown",
            "actions": {
                "interrupting_playback": false,
                "pausing": false,
                "resuming": false,
                "seeking": false,
                "skipping_next": false,
                "skipping_prev": false,
                "toggling_repeat_context": false,
                "toggling_shuffle": false,
                "toggling_repeat_track": false,
                "transferring_playback": false
            },
            "item": null
        }
        """
        
        let data = json.data(using: .utf8)!
        let state: PlaybackState = try decodeModel(from: data)
        
        #expect(state.isPlaying == true)
        #expect(state.currentlyPlayingType == .unknown)
        #expect(state.item == nil)
    }
}

@Suite("RepeatState Tests")
struct RepeatStateTests {
    @Test("Raw values are correct")
    func rawValuesAreCorrect() {
        #expect(PlaybackState.RepeatState.off.rawValue == "off")
        #expect(PlaybackState.RepeatState.track.rawValue == "track")
        #expect(PlaybackState.RepeatState.context.rawValue == "context")
    }

    @Test("Decodes from raw values")
    func decodesFromRawValues() {
        #expect(PlaybackState.RepeatState(rawValue: "off") == .off)
        #expect(PlaybackState.RepeatState(rawValue: "track") == .track)
        #expect(PlaybackState.RepeatState(rawValue: "context") == .context)
        #expect(PlaybackState.RepeatState(rawValue: "invalid") == nil)
    }
}

@Suite("CurrentlyPlayingType Tests")
struct CurrentlyPlayingTypeTests {
    @Test("Raw values are correct")
    func rawValuesAreCorrect() {
        #expect(PlaybackState.CurrentlyPlayingType.track.rawValue == "track")
        #expect(PlaybackState.CurrentlyPlayingType.episode.rawValue == "episode")
        #expect(PlaybackState.CurrentlyPlayingType.ad.rawValue == "ad")
        #expect(PlaybackState.CurrentlyPlayingType.unknown.rawValue == "unknown")
    }

    @Test("Decodes from raw values")
    func decodesFromRawValues() {
        #expect(PlaybackState.CurrentlyPlayingType(rawValue: "track") == .track)
        #expect(PlaybackState.CurrentlyPlayingType(rawValue: "episode") == .episode)
        #expect(PlaybackState.CurrentlyPlayingType(rawValue: "ad") == .ad)
        #expect(PlaybackState.CurrentlyPlayingType(rawValue: "unknown") == .unknown)
        #expect(PlaybackState.CurrentlyPlayingType(rawValue: "invalid") == nil)
    }
}

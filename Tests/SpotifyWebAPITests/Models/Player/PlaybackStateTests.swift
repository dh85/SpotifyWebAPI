import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaybackStateTests {

    @Test
    func decodes_PlaybackState_Track() async throws {
        // Arrange
        let testData = try TestDataLoader.load("playback_state_track.json")

        let state: PlaybackState = try decodeModel(from: testData)

        // Assert - Top Level
        #expect(state.isPlaying == true)
        #expect(state.shuffleState == true)
        #expect(state.repeatState == .context)
        #expect(state.currentlyPlayingType == .track)

        // Assert - Device
        #expect(state.device.type == "smartphone")
        #expect(state.device.name == "Test iPhone")
        #expect(state.device.isActive == true)

        // Assert - Context
        #expect(state.context?.type == "playlist")

        // Assert - Timestamp
        // 1700000000000 ms -> 2023-11-14 22:13:20 UTC
        #expect(state.timestamp.timeIntervalSince1970 == 1_700_000_000)

        // Assert - Item (Polymorphic)
        guard case .track(let track) = state.item else {
            Issue.record("Expected item to be .track")
            return
        }
        #expect(track.name == "Test Track")
        #expect(track.artists.first?.name == "Test Artist")
    }

    @Test
    func decodes_PlaybackState_Episode() async throws {
        // Arrange
        let testData = try TestDataLoader.load("playback_state_episode.json")

        // Act
        let state: PlaybackState = try decodeModel(from: testData)

        // Assert - Top Level
        #expect(state.isPlaying == true)
        #expect(state.shuffleState == false)
        #expect(state.repeatState == .off)
        #expect(state.currentlyPlayingType == .episode)

        // Assert - Device
        #expect(state.device.type == "computer")
        #expect(state.device.name == "Test MacBook")

        // Assert - Context (null in JSON)
        #expect(state.context == nil)

        // Assert - Item (Polymorphic)
        guard case .episode(let episode) = state.item else {
            Issue.record("Expected item to be .episode")
            return
        }
        #expect(episode.name == "Test Episode")
        #expect(episode.show.name == "Test Show")
    }

    @Test
    func decodesWithoutOptionalFields() async throws {
        let json = """
            {
                "device": {
                    "id": "d",
                    "is_active": true,
                    "is_private_session": false,
                    "is_restricted": false,
                    "name": "Device",
                    "type": "computer",
                    "volume_percent": 50,
                    "supports_volume": true
                },
                "repeat_state": "off",
                "shuffle_state": false,
                "context": null,
                "timestamp": 1600000000000,
                "progress_ms": null,
                "is_playing": false,
                "item": null,
                "currently_playing_type": "ad",
                "actions": {}
            }
            """.data(using: .utf8)!

        let state: PlaybackState = try decodeModel(from: json)

        #expect(state.context == nil)
        #expect(state.progressMs == nil)
        #expect(state.item == nil)
        #expect(state.currentlyPlayingType == .ad)
    }

    @Test
    func equatableWorksCorrectly() async throws {
        let testData = try TestDataLoader.load("playback_state_track.json")

        let state1: PlaybackState = try decodeModel(from: testData)
        let state2: PlaybackState = try decodeModel(from: testData)

        #expect(state1 == state2)
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

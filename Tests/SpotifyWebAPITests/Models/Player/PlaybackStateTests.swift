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
        #expect(state.device.type == .smartphone)
        #expect(state.device.name == "Test iPhone")
        #expect(state.device.isActive == true)

        // Assert - Context
        #expect(state.context?.type == .playlist)

        // Assert - Timestamp
        // 1700000000000 ms -> 2023-11-14 22:13:20 UTC
        #expect(state.timestamp.timeIntervalSince1970 == 1_700_000_000)

        // Assert - Item (Polymorphic)
        guard case .track(let track) = state.item else {
            Issue.record("Expected item to be .track")
            return
        }
        #expect(track.name == "Test Track")
        #expect(track.artists?.first?.name == "Test Artist")
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
        #expect(state.device.type == .computer)
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
}

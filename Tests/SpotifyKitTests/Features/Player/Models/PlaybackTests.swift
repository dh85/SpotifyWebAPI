import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PlaybackTests {

  @Test
  func decodes_currentlyPlaying_Track() async throws {
    let testData = try TestDataLoader.load("playback_context_track.json")

    let context: CurrentlyPlayingContext = try decodeModel(from: testData)

    #expect(context.isPlaying == true)
    #expect(context.progressMs == 123456)
    #expect(context.currentlyPlayingType == "track")
    #expect(context.context?.type == "playlist")
    #expect(context.actions.resuming == true)

    // Verify Timestamp (1610000000000 ms is 2021-01-07T06:13:20Z)
    #expect(context.timestamp.timeIntervalSince1970 == 1_610_000_000)

    // Verify Polymorphic Item
    guard case .track(let track) = context.item else {
      Issue.record("Expected item to be a .track, but it was not.")
      return
    }
    #expect(track.name == "Mock Track Title")
    #expect(track.album?.name == "Mock Album")
  }

  @Test
  func decodes_currentlyPlaying_Episode() async throws {
    // Arrange
    let testData = try TestDataLoader.load("playback_context_episode.json")

    // Act
    let context: CurrentlyPlayingContext = try decodeModel(from: testData)

    // Assert
    #expect(context.isPlaying == true)
    #expect(context.progressMs == 654321)
    #expect(context.currentlyPlayingType == "episode")
    #expect(context.context?.type == "show")

    // Verify Timestamp (1620000000000 ms is 2021-05-03T00:00:00Z)
    #expect(context.timestamp.timeIntervalSince1970 == 1_620_000_000)

    // Verify Polymorphic Item
    guard case .episode(let episode) = context.item else {
      Issue.record("Expected item to be a .episode, but it was not.")
      return
    }
    #expect(episode.name == "Mock Episode Title")
    #expect(episode.show?.name == "Mock Show")
  }

  @Test
  func decodes_currentlyPlaying_Ad_asNilItem() async throws {
    // Arrange
    // This JSON includes all *required* keys from the custom init:
    // is_playing, currently_playing_type, actions, timestamp
    let adJSON = """
      {
          "timestamp": 1600000000000,
          "progress_ms": 1000,
          "is_playing": true,
          "currently_playing_type": "ad",
          "actions": { "disallows": {} },
          "item": null,
          "context": null
      }
      """
    let testData = adJSON.data(using: .utf8)!

    // Act
    let context: CurrentlyPlayingContext = try decodeModel(from: testData)

    // Assert
    #expect(context.currentlyPlayingType == "ad")
    #expect(context.item == nil, "Item should be nil when type is 'ad'")
    #expect(context.isPlaying == true)
  }
}

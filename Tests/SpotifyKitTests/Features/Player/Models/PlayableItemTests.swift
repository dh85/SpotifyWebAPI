import Foundation
import Testing

@testable import SpotifyKit

@Suite("PlayableItem Tests")
struct PlayableItemTests {
  @Test("Different types are not equal")
  func differentTypesAreNotEqual() throws {
    let trackData = try TestDataLoader.load("playback_context_track.json")
    let episodeData = try TestDataLoader.load("playback_context_episode.json")

    let trackContext: CurrentlyPlayingContext = try decodeModel(from: trackData)
    let episodeContext: CurrentlyPlayingContext = try decodeModel(from: episodeData)

    guard case .track = trackContext.item else {
      Issue.record("Expected track")
      return
    }

    guard case .episode = episodeContext.item else {
      Issue.record("Expected episode")
      return
    }

    #expect(trackContext.item != episodeContext.item)
  }
}

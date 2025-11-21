import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaybackStateTests {
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

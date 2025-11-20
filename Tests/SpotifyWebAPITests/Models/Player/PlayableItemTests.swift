import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("PlayableItem Tests")
struct PlayableItemTests {
    @Test("Matches track case")
    func matchesTrackCase() throws {
        let testData = try TestDataLoader.load("playback_context_track.json")
        let context: CurrentlyPlayingContext = try decodeModel(from: testData)
        
        guard case .track(let track) = context.item else {
            Issue.record("Expected track case")
            return
        }
        #expect(track.name == "Mock Track Title")
        #expect(track.id == "track123")
    }
    
    @Test("Matches episode case")
    func matchesEpisodeCase() throws {
        let testData = try TestDataLoader.load("playback_context_episode.json")
        let context: CurrentlyPlayingContext = try decodeModel(from: testData)
        
        guard case .episode(let episode) = context.item else {
            Issue.record("Expected episode case")
            return
        }
        #expect(episode.name == "Mock Episode Title")
        #expect(episode.id == "episode123")
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() throws {
        let trackData = try TestDataLoader.load("playback_context_track.json")
        let episodeData = try TestDataLoader.load("playback_context_episode.json")
        
        let context1: CurrentlyPlayingContext = try decodeModel(from: trackData)
        let context2: CurrentlyPlayingContext = try decodeModel(from: trackData)
        let context3: CurrentlyPlayingContext = try decodeModel(from: episodeData)
        
        #expect(context1.item == context2.item)
        #expect(context1.item != context3.item)
    }
    
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

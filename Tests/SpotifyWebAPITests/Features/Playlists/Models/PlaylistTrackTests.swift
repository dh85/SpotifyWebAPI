import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTrackTests {
    
    @Test("Decodes track")
    func decodesTrack() throws {
        let data = try TestDataLoader.load("track_full")
        let playlistTrack: PlaylistTrack = try decodeModel(from: data)
        
        if case .track(let track) = playlistTrack {
            #expect(track.name == "Test Track")
        } else {
            Issue.record("Expected track")
        }
    }
    
    @Test("Decodes episode")
    func decodesEpisode() throws {
        let data = try TestDataLoader.load("episode_full")
        let playlistTrack: PlaylistTrack = try decodeModel(from: data)
        
        if case .episode(let episode) = playlistTrack {
            #expect(episode.name == "Episode 1")
        } else {
            Issue.record("Expected episode")
        }
    }
    
    @Test("Throws error for invalid data")
    func throwsErrorForInvalidData() throws {
        let json = "{\"invalid\": \"data\"}"
        
        #expect(throws: DecodingError.self) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            _ = try decoder.decode(PlaylistTrack.self, from: json.data(using: .utf8)!)
        }
    }
    
    @Test("Encodes track")
    func encodesTrack() throws {
        let data = try TestDataLoader.load("track_full")
        let track: Track = try decodeModel(from: data)
        let playlistTrack = PlaylistTrack.track(track)
        
        let encoded = try encodeModel(playlistTrack)
        let decoded: PlaylistTrack = try decodeModel(from: encoded)
        
        #expect(decoded == playlistTrack)
    }
    
    @Test("Encodes episode")
    func encodesEpisode() throws {
        let data = try TestDataLoader.load("episode_full")
        let episode: Episode = try decodeModel(from: data)
        let playlistTrack = PlaylistTrack.episode(episode)
        
        let encoded = try encodeModel(playlistTrack)
        let decoded: PlaylistTrack = try decodeModel(from: encoded)
        
        #expect(decoded == playlistTrack)
    }
}

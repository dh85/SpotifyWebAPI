import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyObjectTypeTests {

    @Test
    func hasCorrectRawValues() {
        #expect(SpotifyObjectType.album.rawValue == "album")
        #expect(SpotifyObjectType.artist.rawValue == "artist")
        #expect(SpotifyObjectType.audiobook.rawValue == "audiobook")
        #expect(SpotifyObjectType.chapter.rawValue == "chapter")
        #expect(SpotifyObjectType.episode.rawValue == "episode")
        #expect(SpotifyObjectType.playlist.rawValue == "playlist")
        #expect(SpotifyObjectType.show.rawValue == "show")
        #expect(SpotifyObjectType.track.rawValue == "track")
        #expect(SpotifyObjectType.user.rawValue == "user")
    }

    @Test
    func equatableWorksCorrectly() {
        #expect(SpotifyObjectType.album == SpotifyObjectType.album)
        #expect(SpotifyObjectType.album != SpotifyObjectType.artist)
    }

    @Test
    func decodesFromRawValue() {
        #expect(SpotifyObjectType(rawValue: "album") == .album)
        #expect(SpotifyObjectType(rawValue: "artist") == .artist)
        #expect(SpotifyObjectType(rawValue: "track") == .track)
        #expect(SpotifyObjectType(rawValue: "invalid") == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let encoder = JSONEncoder()
        let albumData = try encoder.encode(SpotifyObjectType.album)
        let trackData = try encoder.encode(SpotifyObjectType.track)

        #expect(String(data: albumData, encoding: .utf8) == "\"album\"")
        #expect(String(data: trackData, encoding: .utf8) == "\"track\"")
    }

    @Test
    func decodesCorrectly() throws {
        let decoder = JSONDecoder()
        let album = try decoder.decode(
            SpotifyObjectType.self, from: "\"album\"".data(using: .utf8)!)
        let track = try decoder.decode(
            SpotifyObjectType.self, from: "\"track\"".data(using: .utf8)!)

        #expect(album == .album)
        #expect(track == .track)
    }
}

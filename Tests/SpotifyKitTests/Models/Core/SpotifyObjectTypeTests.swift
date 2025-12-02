import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyObjectTypeTests {

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

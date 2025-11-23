import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AlbumTypeTests {

    @Test
    func decodesFromRawValue() {
        #expect(AlbumType(rawValue: "album") == .album)
        #expect(AlbumType(rawValue: "single") == .single)
        #expect(AlbumType(rawValue: "compilation") == .compilation)
        #expect(AlbumType(rawValue: "invalid") == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let encoder = JSONEncoder()
        let albumData = try encoder.encode(AlbumType.album)
        let singleData = try encoder.encode(AlbumType.single)
        let compilationData = try encoder.encode(AlbumType.compilation)

        #expect(String(data: albumData, encoding: .utf8) == "\"album\"")
        #expect(String(data: singleData, encoding: .utf8) == "\"single\"")
        #expect(String(data: compilationData, encoding: .utf8) == "\"compilation\"")
    }

    @Test
    func decodesCorrectly() throws {
        let decoder = JSONDecoder()
        let album = try decoder.decode(AlbumType.self, from: "\"album\"".data(using: .utf8)!)
        let single = try decoder.decode(AlbumType.self, from: "\"single\"".data(using: .utf8)!)
        let compilation = try decoder.decode(
            AlbumType.self, from: "\"compilation\"".data(using: .utf8)!)

        #expect(album == .album)
        #expect(single == .single)
        #expect(compilation == .compilation)
    }
}

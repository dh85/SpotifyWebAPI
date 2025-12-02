import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PlaybackOffsetTests {

    @Test
    func positionFactoryCreatesCorrectOffset() {
        let offset = PlaybackOffset.position(5)
        
        #expect(offset.position == 5)
        #expect(offset.uri == nil)
    }

    @Test
    func uriFactoryCreatesCorrectOffset() {
        let offset = PlaybackOffset.uri("spotify:track:123")
        
        #expect(offset.position == nil)
        #expect(offset.uri == "spotify:track:123")
    }

    @Test
    func encodesPositionCorrectly() throws {
        let offset = PlaybackOffset.position(3)
        let data = try encodeModel(offset)
        let json = String(data: data, encoding: .utf8)
        
        #expect(json == #"{"position":3}"#)
    }

    @Test
    func encodesUriCorrectly() throws {
        let offset = PlaybackOffset.uri("spotify:track:abc")
        let data = try encodeModel(offset)
        let json = String(data: data, encoding: .utf8)
        
        #expect(json == #"{"uri":"spotify:track:abc"}"#)
    }
}

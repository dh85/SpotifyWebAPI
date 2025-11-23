import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("PlaybackContext Tests")
struct PlaybackContextTests {    
    @Test("Encodes correctly")
    func encodesCorrectly() throws {
        let context = PlaybackContext(
            type: "artist",
            href: URL(string: "https://api.spotify.com/v1/artists/xyz")!,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/artist/xyz")),
            uri: "spotify:artist:xyz"
        )
        
        let data = try encodeModel(context)
        let decoded: PlaybackContext = try decodeModel(from: data)
        
        #expect(decoded == context)
    }
}

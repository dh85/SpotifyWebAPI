import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("PlaybackContext Tests")
struct PlaybackContextTests {
    @Test("Decodes with all fields")
    func decodesWithAllFields() throws {
        let json = """
        {
            "type": "playlist",
            "href": "https://api.spotify.com/v1/playlists/abc123",
            "external_urls": {
                "spotify": "https://open.spotify.com/playlist/abc123"
            },
            "uri": "spotify:playlist:abc123"
        }
        """.data(using: .utf8)!
        
        let context: PlaybackContext = try decodeModel(from: json)
        
        #expect(context.type == "playlist")
        #expect(context.href.absoluteString == "https://api.spotify.com/v1/playlists/abc123")
        #expect(context.externalUrls.spotify?.absoluteString == "https://open.spotify.com/playlist/abc123")
        #expect(context.uri == "spotify:playlist:abc123")
    }
    
    @Test("Decodes different context types")
    func decodesDifferentContextTypes() throws {
        let types = ["album", "artist", "playlist", "show"]
        
        for type in types {
            let json = """
            {
                "type": "\(type)",
                "href": "https://api.spotify.com/v1/\(type)s/id",
                "external_urls": {},
                "uri": "spotify:\(type):id"
            }
            """.data(using: .utf8)!
            
            let context: PlaybackContext = try decodeModel(from: json)
            #expect(context.type == type)
        }
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() throws {
        let context1 = PlaybackContext(
            type: "album",
            href: URL(string: "https://api.spotify.com/v1/albums/123")!,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/album/123")),
            uri: "spotify:album:123"
        )
        
        let context2 = PlaybackContext(
            type: "album",
            href: URL(string: "https://api.spotify.com/v1/albums/123")!,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/album/123")),
            uri: "spotify:album:123"
        )
        
        let context3 = PlaybackContext(
            type: "playlist",
            href: URL(string: "https://api.spotify.com/v1/playlists/456")!,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/playlist/456")),
            uri: "spotify:playlist:456"
        )
        
        #expect(context1 == context2)
        #expect(context1 != context3)
    }
    
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

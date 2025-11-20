import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedArtistTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "external_urls": {
                    "spotify": "https://open.spotify.com/artist/artist123"
                },
                "href": "https://api.spotify.com/v1/artists/artist123",
                "id": "artist123",
                "name": "Test Artist",
                "type": "artist",
                "uri": "spotify:artist:artist123"
            }
            """
        let data = json.data(using: .utf8)!
        let artist: SimplifiedArtist = try decodeModel(from: data)

        #expect(artist.id == "artist123")
        #expect(artist.name == "Test Artist")
        #expect(artist.type == .artist)
        #expect(artist.uri == "spotify:artist:artist123")
        #expect(artist.href.absoluteString == "https://api.spotify.com/v1/artists/artist123")
        #expect(artist.externalUrls.spotify?.absoluteString == "https://open.spotify.com/artist/artist123")
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "external_urls": {
                    "spotify": "https://open.spotify.com/artist/eq123"
                },
                "href": "https://api.spotify.com/v1/artists/eq123",
                "id": "eq123",
                "name": "Equal Artist",
                "type": "artist",
                "uri": "spotify:artist:eq123"
            }
            """
        let data = json.data(using: .utf8)!
        let artist1: SimplifiedArtist = try decodeModel(from: data)
        let artist2: SimplifiedArtist = try decodeModel(from: data)

        #expect(artist1 == artist2)
    }
}

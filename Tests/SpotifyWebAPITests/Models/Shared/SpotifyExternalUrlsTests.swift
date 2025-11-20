import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyExternalUrlsTests {

    @Test
    func decodesWithSpotifyUrl() throws {
        let json = """
            {
                "spotify": "https://open.spotify.com/track/123"
            }
            """
        let data = json.data(using: .utf8)!
        let externalUrls: SpotifyExternalUrls = try decodeModel(from: data)

        #expect(externalUrls.spotify?.absoluteString == "https://open.spotify.com/track/123")
    }

    @Test
    func decodesWithNullUrl() throws {
        let json = """
            {
                "spotify": null
            }
            """
        let data = json.data(using: .utf8)!
        let externalUrls: SpotifyExternalUrls = try decodeModel(from: data)

        #expect(externalUrls.spotify == nil)
    }

    @Test
    func decodesWithEmptyObject() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let externalUrls: SpotifyExternalUrls = try decodeModel(from: data)

        #expect(externalUrls.spotify == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let externalUrls = SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/track/123")
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(externalUrls)
        let decoded: SpotifyExternalUrls = try JSONDecoder().decode(
            SpotifyExternalUrls.self, from: data)

        #expect(decoded == externalUrls)
    }

    @Test
    func equatableWorksCorrectly() {
        let urls1 = SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/track/123"))
        let urls2 = SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/track/123"))
        let urls3 = SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/track/456"))
        let urls4 = SpotifyExternalUrls(spotify: nil)

        #expect(urls1 == urls2)
        #expect(urls1 != urls3)
        #expect(urls1 != urls4)
    }
}

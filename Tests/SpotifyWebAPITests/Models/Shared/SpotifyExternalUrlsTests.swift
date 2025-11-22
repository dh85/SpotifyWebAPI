import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyExternalUrlsTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let urls = SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/object"))
        try expectCodableRoundTrip(urls)
    }
}

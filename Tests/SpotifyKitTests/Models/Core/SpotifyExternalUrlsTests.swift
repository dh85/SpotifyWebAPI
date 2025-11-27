import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyExternalUrlsTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let urls = SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/object"))
        try expectCodableRoundTrip(urls)
    }
}

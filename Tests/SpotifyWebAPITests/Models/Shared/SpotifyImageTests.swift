import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyImageTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let image = SpotifyImage(
            url: URL(string: "https://image/640")!,
            height: 640,
            width: 640
        )
        try expectCodableRoundTrip(image)
    }
}

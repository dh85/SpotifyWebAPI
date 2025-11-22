import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyCopyrightTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let copyright = SpotifyCopyright(text: "© 2024 Example", type: .copyright)
        try expectCodableRoundTrip(copyright)
    }
}

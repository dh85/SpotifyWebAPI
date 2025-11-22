import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AuthorTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let author = Author(name: "Test Author")
        try expectCodableRoundTrip(author)
    }
}

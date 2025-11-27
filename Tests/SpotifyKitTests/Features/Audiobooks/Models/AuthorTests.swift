import Foundation
import Testing

@testable import SpotifyKit

@Suite struct AuthorTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let author = Author(name: "Test Author")
        try expectCodableRoundTrip(author)
    }
}

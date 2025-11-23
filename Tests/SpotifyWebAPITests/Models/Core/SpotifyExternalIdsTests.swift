import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyExternalIdsTests {

    @Test
    func supportsCodableRoundTrip() throws {
        let ids = SpotifyExternalIds(isrc: "US-S1Z-99-00001", ean: "1234567890123", upc: "012345678905")
        try expectCodableRoundTrip(ids)
    }
}

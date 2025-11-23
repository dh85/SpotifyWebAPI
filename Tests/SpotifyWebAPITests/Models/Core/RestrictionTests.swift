import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct RestrictionTests {

    @Test
    func decodesRestrictionReason() throws {
        let json = """
        { "reason": "payment_required" }
        """
        let restriction: Restriction = try decodeModel(from: Data(json.utf8))

        #expect(restriction.reason == .paymentRequired)
        try expectCodableRoundTrip(restriction)
    }
}

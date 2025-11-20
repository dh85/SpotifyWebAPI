import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct RestrictionTests {

    @Test
    func reasonHasCorrectRawValues() {
        #expect(Restriction.Reason.market.rawValue == "market")
        #expect(Restriction.Reason.product.rawValue == "product")
        #expect(Restriction.Reason.explicit.rawValue == "explicit")
        #expect(Restriction.Reason.paymentRequired.rawValue == "payment_required")
    }

    @Test
    func reasonDecodesFromRawValue() {
        #expect(Restriction.Reason(rawValue: "market") == .market)
        #expect(Restriction.Reason(rawValue: "product") == .product)
        #expect(Restriction.Reason(rawValue: "explicit") == .explicit)
        #expect(Restriction.Reason(rawValue: "payment_required") == .paymentRequired)
        #expect(Restriction.Reason(rawValue: "invalid") == nil)
    }

    @Test
    func decodesCorrectly() throws {
        let json = """
            {
                "reason": "market"
            }
            """
        let data = json.data(using: .utf8)!
        let restriction: Restriction = try decodeModel(from: data)

        #expect(restriction.reason == .market)
    }

    @Test
    func decodesAllReasons() throws {
        let reasons = ["market", "product", "explicit", "payment_required"]
        let expected: [Restriction.Reason] = [.market, .product, .explicit, .paymentRequired]

        for (rawValue, expectedReason) in zip(reasons, expected) {
            let json = """
                {
                    "reason": "\(rawValue)"
                }
                """
            let data = json.data(using: .utf8)!
            let restriction: Restriction = try decodeModel(from: data)
            #expect(restriction.reason == expectedReason)
        }
    }

    @Test
    func encodesCorrectly() throws {
        let restriction = Restriction(reason: .market)
        let encoder = JSONEncoder()
        let data = try encoder.encode(restriction)
        let decoded: Restriction = try JSONDecoder().decode(Restriction.self, from: data)

        #expect(decoded == restriction)
    }

    @Test
    func equatableWorksCorrectly() {
        let restriction1 = Restriction(reason: .market)
        let restriction2 = Restriction(reason: .market)
        let restriction3 = Restriction(reason: .product)

        #expect(restriction1 == restriction2)
        #expect(restriction1 != restriction3)
    }
}

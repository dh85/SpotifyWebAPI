public struct Restriction: Codable, Sendable, Equatable {
    public enum Reason: String, Codable, Equatable, Sendable {
        case market
        case product
        case explicit
        case paymentRequired = "payment_required"
    }

    public let reason: Reason
}

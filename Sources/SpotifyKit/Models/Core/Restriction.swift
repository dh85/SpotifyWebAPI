/// Content restriction information.
///
/// Indicates why content is restricted or unavailable.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
public struct Restriction: Codable, Sendable, Equatable {
    /// The reason for the restriction.
    public enum Reason: String, Codable, Equatable, Sendable {
        /// Content is not available in the given market.
        case market
        /// Content is not available for the user's subscription type.
        case product
        /// Content is explicit and restricted by user settings.
        case explicit
        /// Payment is required to access the content.
        case paymentRequired = "payment_required"
    }

    /// The reason why the content is restricted.
    public let reason: Reason
}

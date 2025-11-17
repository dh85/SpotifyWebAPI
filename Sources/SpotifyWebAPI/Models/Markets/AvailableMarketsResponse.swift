import Foundation

/// Wrapper for the `GET /v1/markets` endpoint response.
struct AvailableMarketsResponse: Codable, Sendable, Equatable {
    let markets: [String]
}

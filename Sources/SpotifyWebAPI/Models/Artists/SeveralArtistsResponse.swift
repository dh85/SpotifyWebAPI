import Foundation

/// Wrapper for the `GET /v1/artists` endpoint response.
struct SeveralArtistsResponse: Codable, Sendable, Equatable {
    let artists: [Artist]
}

import Foundation

/// Wrapper for the `GET /v1/albums` endpoint response.
struct SeveralAlbumsResponse: Codable, Sendable, Equatable {
    let albums: [Album]
}

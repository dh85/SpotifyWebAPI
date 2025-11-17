import Foundation

/// Wrapper for the `GET /v1/episodes` endpoint response.
struct SeveralEpisodesResponse: Codable, Sendable, Equatable {
    let episodes: [Episode]
}

import Foundation

/// Wrapper for the `GET /v1/artists/{id}/top-tracks` endpoint response.
struct TopTracksResponse: Codable, Sendable, Equatable {
    let tracks: [Track]
}

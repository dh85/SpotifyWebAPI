import Foundation

/// Wrapper for the `GET /v1/shows` endpoint response.
struct SeveralShowsResponse: Codable, Sendable, Equatable {
    /// A list of simplified shows.
    /// Note: Returns 'SimplifiedShow' objects, not full 'Show' objects.
    let shows: [SimplifiedShow]
}

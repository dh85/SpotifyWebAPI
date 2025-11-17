import Foundation

/// Wrapper for the `GET /v1/me/following` endpoint response.
struct FollowedArtistsResponse: Codable, Sendable, Equatable {
    let artists: CursorBasedPage<Artist>
}

import Foundation

/// Follower information for a user or artist.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artist)
public struct SpotifyFollowers: Codable, Sendable, Equatable {
    /// API endpoint URL (always null in current API version).
    public let href: URL?
    /// The total number of followers.
    public let total: Int
}

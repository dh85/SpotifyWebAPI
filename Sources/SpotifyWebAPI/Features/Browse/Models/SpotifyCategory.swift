import Foundation

/// A Spotify browse category object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-categories)
public struct SpotifyCategory: Codable, Sendable, Equatable {
    /// API endpoint URL for full category details.
    public let href: URL
    /// Category icon images.
    public let icons: [SpotifyImage]
    /// The Spotify category ID.
    public let id: String
    /// Category name.
    public let name: String
}

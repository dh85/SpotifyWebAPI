import Foundation

/// A full artist object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artist)
public struct Artist: Codable, Sendable, Equatable {
    /// External URLs for this artist.
    public let externalUrls: SpotifyExternalUrls?
    /// Follower information.
    public let followers: SpotifyFollowers?
    /// Genres associated with the artist.
    public let genres: [String]?
    /// API endpoint URL for full artist details.
    public let href: URL?
    /// The Spotify ID.
    public let id: String?
    /// Artist images in various sizes.
    public let images: [SpotifyImage]?
    /// Artist name.
    public let name: String
    /// Popularity score (0-100).
    public let popularity: Int?
    /// Object type (always "artist").
    public let type: SpotifyObjectType
    /// The Spotify URI.
    public let uri: String?
}

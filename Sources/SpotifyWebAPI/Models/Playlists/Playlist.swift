import Foundation

/// A full playlist object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlist)
public struct Playlist: Codable, Sendable, Equatable {
    /// The Spotify ID.
    public let id: String
    /// Playlist name.
    public let name: String
    /// API endpoint URL for full playlist details.
    public let href: URL
    /// The Spotify URI.
    public let uri: String
    /// Whether the playlist is collaborative.
    public let collaborative: Bool
    /// Playlist description.
    public let description: String?
    /// External URLs for this playlist.
    public let externalUrls: SpotifyExternalUrls?
    /// Playlist cover images.
    public let images: [SpotifyImage]
    /// Playlist owner.
    public let owner: SpotifyPublicUser
    /// Whether the playlist is public.
    public let isPublic: Bool?
    /// Snapshot ID for playlist versioning.
    public let snapshotId: String?
    /// Follower information.
    public let followers: SpotifyFollowers?
    /// Tracks in the playlist.
    public let tracks: Page<PlaylistTrackItem>

    enum CodingKeys: String, CodingKey {
        case id, name, href, uri, collaborative, description, externalUrls,
            images, owner
        case isPublic = "public"
        case snapshotId, followers, tracks
    }
}

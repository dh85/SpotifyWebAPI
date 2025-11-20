import Foundation

/// A full playlist object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlist)
public struct Playlist: Codable, Sendable, Equatable {
    /// Whether the playlist is collaborative.
    public let collaborative: Bool
    /// Playlist description. Can be null.
    public let description: String?
    /// Known external URLs for this playlist.
    public let externalUrls: SpotifyExternalUrls?
    /// A link to the Web API endpoint providing full details of the playlist.
    public let href: URL
    /// The Spotify ID for the playlist.
    public let id: String
    /// Images for the playlist. The array may be empty or contain up to three images.
    public let images: [SpotifyImage]
    /// The name of the playlist.
    public let name: String
    /// The user who owns the playlist.
    public let owner: SpotifyPublicUser
    /// The playlist's public/private status. Can be null.
    public let isPublic: Bool?
    /// The version identifier for the current playlist.
    public let snapshotId: String?
    /// The tracks of the playlist.
    public let tracks: Page<PlaylistTrackItem>
    /// The object type ("playlist").
    public let type: SpotifyObjectType
    /// The Spotify URI for the playlist.
    public let uri: String

    enum CodingKeys: String, CodingKey {
        case collaborative, description, externalUrls, href, id, images, name,
            owner, snapshotId, tracks, type, uri
        case isPublic = "public"
    }
}

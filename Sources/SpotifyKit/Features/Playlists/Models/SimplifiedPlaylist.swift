import Foundation

/// A simplified playlist object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists)
public struct SimplifiedPlaylist: Codable, Sendable, Equatable, SpotifyResource {
  /// Whether the playlist is collaborative.
  public let collaborative: Bool
  /// The playlist description. Can be null.
  public let description: String?
  /// Known external URLs for this playlist.
  public let externalUrls: SpotifyExternalUrls?
  /// A link to the Web API endpoint providing full details of the playlist.
  public let href: URL
  /// The Spotify ID for the playlist.
  public let id: String
  /// Images for the playlist. Can be null or contain up to three images.
  public let images: [SpotifyImage]?
  /// The name of the playlist.
  public let name: String
  /// The user who owns the playlist.
  public let owner: SpotifyPublicUser?
  /// The playlist's public/private status. Can be null.
  public let isPublic: Bool?
  /// The version identifier for the current playlist.
  public let snapshotId: String
  /// A collection containing a link to the Web API endpoint where full details of the playlist's tracks can be retrieved, along with the total number of tracks in the playlist.
  public let tracks: PlaylistTracksRef?
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

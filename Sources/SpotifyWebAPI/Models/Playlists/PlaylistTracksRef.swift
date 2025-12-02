import Foundation

/// A reference to the tracks in a playlist.
///
/// Contains a link to the Web API endpoint for full track details and the total number of tracks.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists)
public struct PlaylistTracksRef: Codable, Sendable, Equatable {
  /// A link to the Web API endpoint where full details of the playlist's tracks can be retrieved.
  public let href: URL?
  /// The total number of tracks in the playlist.
  public let total: Int
}

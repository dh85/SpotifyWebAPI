/// The type of album.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public enum AlbumType: String, Codable, Equatable, Sendable {
  /// A standard album release.
  case album
  /// A single release (typically 1-3 tracks).
  case single
  /// A compilation album (collection of tracks from various sources).
  case compilation
}

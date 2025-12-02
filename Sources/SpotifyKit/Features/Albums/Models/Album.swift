import Foundation

/// A full album object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public struct Album: Codable, Sendable, Equatable, StandardSpotifyResource {
  /// Album type (e.g., "album", "single", "compilation").
  public let albumType: AlbumType?
  /// Total number of tracks.
  public let totalTracks: Int?
  /// Markets where the album is available (ISO 3166-1 alpha-2 codes).
  public let availableMarkets: [String]?
  /// External URLs for this album.
  public let externalUrls: SpotifyExternalUrls?
  /// API endpoint URL for full album details.
  public let href: URL?
  /// The Spotify ID.
  public let id: String?
  /// Cover art images in various sizes. Can be null.
  public let images: [SpotifyImage]?
  /// Album name.
  public let name: String
  /// Release date (e.g., "1981-12-15").
  public let releaseDate: String?
  /// Precision of the release date.
  public let releaseDatePrecision: ReleaseDatePrecision?
  /// Content restriction information.
  public let restrictions: Restriction?
  /// Object type (always "album").
  public let type: SpotifyObjectType
  /// The Spotify URI.
  public let uri: String?
  /// Artists who performed the album.
  public let artists: [SimplifiedArtist]?
  /// Tracks in the album.
  public let tracks: Page<SimplifiedTrack>?
  /// Copyright statements.
  public let copyrights: [SpotifyCopyright]?
  /// External IDs (e.g., UPC, EAN, ISRC).
  public let externalIds: SpotifyExternalIds?
  /// Label that released the album.
  public let label: String?
  /// Popularity score (0-100).
  public let popularity: Int?
}

extension Album {

}

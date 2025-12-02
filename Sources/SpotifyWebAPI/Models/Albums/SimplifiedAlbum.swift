import Foundation

/// Simplified album object containing core album information.
///
/// This is a lighter version of the full Album object, typically returned in contexts
/// where complete album details are not needed (e.g., within tracks, search results).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public struct SimplifiedAlbum: Codable, Sendable, Equatable {
  /// The type of the album (album, single, or compilation).
  public let albumType: AlbumType
  /// The number of tracks in the album.
  public let totalTracks: Int
  /// The markets in which the album is available (ISO 3166-1 alpha-2 country codes).
  public let availableMarkets: [String]
  /// Known external URLs for this album.
  public let externalUrls: SpotifyExternalUrls
  /// A link to the Web API endpoint providing full details of the album.
  public let href: URL
  /// The Spotify ID for the album.
  public let id: String
  /// The cover art for the album in various sizes.
  public let images: [SpotifyImage]
  /// The name of the album.
  public let name: String
  /// The date the album was first released (e.g., "1981-12", "1981").
  public let releaseDate: String
  /// The precision with which release_date value is known (year, month, or day).
  public let releaseDatePrecision: ReleaseDatePrecision
  /// Included in the response when a content restriction is applied.
  public let restrictions: Restriction?
  /// The object type (always "album").
  public let type: SpotifyObjectType
  /// The Spotify URI for the album.
  public let uri: String
  /// The artists of the album.
  public let artists: [SimplifiedArtist]
  /// The field is present when getting an artist's albums (album, single, compilation, appears_on).
  public let albumGroup: AlbumGroup?
}

/// The relationship between an artist and an album.
public enum AlbumGroup: String, Codable, Sendable, Equatable {
  /// The album is released by the artist.
  case album
  /// The album is a single released by the artist.
  case single
  /// The album is a compilation that includes the artist.
  case compilation
  /// The album features the artist but is not their primary release.
  case appearsOn = "appears_on"
}

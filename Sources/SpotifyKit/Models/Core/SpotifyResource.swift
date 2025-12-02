import Foundation

/// Common metadata returned by many Spotify resources (albums, artists, playlists, etc.).
///
/// By conforming to this protocol, models can expose a consistent surface for
/// identifying resources without duplicating helper code.
public protocol SpotifyResource: Sendable {
  var externalUrls: SpotifyExternalUrls? { get }
  var hrefURL: URL? { get }
  var spotifyID: String? { get }
  var displayName: String { get }
  var objectType: SpotifyObjectType { get }
  var spotifyURI: String? { get }
}

extension SpotifyResource {
  public var resourceSummary: String {
    "\(displayName) (\(spotifyID ?? "unknown"))"
  }
}

/// A protocol to provide default implementations for SpotifyResource conformance
/// by automatically mapping standard Spotify API property names.
///
/// Models that have the standard Spotify properties (href, id, name, type, uri)
/// can conform to this protocol and get automatic SpotifyResource conformance.
public protocol StandardSpotifyResource: SpotifyResource {
  /// The API endpoint URL (maps to `hrefURL`)
  var href: URL? { get }
  /// The Spotify ID (maps to `spotifyID`)
  var id: String? { get }
  /// The display name (maps to `displayName`)
  var name: String { get }
  /// The object type (maps to `objectType`)
  var type: SpotifyObjectType { get }
  /// The Spotify URI (maps to `spotifyURI`)
  var uri: String? { get }
}

extension StandardSpotifyResource {
  public var hrefURL: URL? { href }
  public var spotifyID: String? { id }
  public var displayName: String { name }
  public var objectType: SpotifyObjectType { type }
  public var spotifyURI: String? { uri }
}

import Foundation

/// Information about the originally requested track when track relinking is applied.
///
/// Track relinking occurs when a track is not available in a given market, and Spotify returns a different track instead.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/concepts/track-relinking)
public struct LinkedFrom: Codable, Sendable, Equatable {
  /// External URLs for the originally requested track.
  public let externalUrls: SpotifyExternalUrls?
  /// API endpoint URL for the originally requested track.
  public let href: URL?
  /// The Spotify ID of the originally requested track.
  public let id: String?
  /// Object type (always "track" when present).
  public let type: SpotifyObjectType?
  /// The Spotify URI of the originally requested track.
  public let uri: String?
}

import Foundation

/// A simplified show object.
///
/// Contains basic show information without the episodes list.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-show)
public struct SimplifiedShow: Codable, Sendable, Equatable {
  /// Markets where the show is available (ISO 3166-1 alpha-2 codes).
  /// Only present when market is not provided in the request.
  public let availableMarkets: [String]?
  /// Copyright statements for the show.
  public let copyrights: [SpotifyCopyright]?
  /// A description of the show (plain text).
  public let description: String?
  /// A description of the show (HTML format).
  public let htmlDescription: String?
  /// Whether the show has explicit content.
  public let explicit: Bool
  /// External URLs for this show.
  public let externalUrls: SpotifyExternalUrls?
  /// API endpoint URL for full show details.
  public let href: URL?
  /// The Spotify ID.
  public let id: String?
  /// Cover art images in various sizes.
  public let images: [SpotifyImage]?
  /// Whether the show is hosted outside of Spotify's CDN.
  public let isExternallyHosted: Bool?
  /// Languages used in the show (ISO 639 codes).
  public let languages: [String]?
  /// The media type of the show (e.g., "audio").
  public let mediaType: String?
  /// The show name.
  public let name: String?
  /// The publisher of the show.
  public let publisher: String?
  /// Object type (always "show").
  public let type: SpotifyObjectType
  /// The Spotify URI.
  public let uri: String?
  /// The total number of episodes in the show.
  public let totalEpisodes: Int?

}

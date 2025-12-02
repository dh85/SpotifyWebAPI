import Foundation

/// Simplified audiobook object containing core audiobook information.
///
/// This is a lighter version of the full Audiobook object, typically returned in contexts
/// where complete audiobook details are not needed (e.g., within chapters, search results).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
public struct SimplifiedAudiobook: Codable, Sendable, Equatable {
  /// The author(s) for the audiobook.
  public let authors: [Author]
  /// A list of the countries in which the audiobook can be played (ISO 3166-1 alpha-2 country codes).
  public let availableMarkets: [String]
  /// The copyright statements of the audiobook.
  public let copyrights: [SpotifyCopyright]
  /// A description of the audiobook.
  public let description: String
  /// A description of the audiobook in HTML format.
  public let htmlDescription: String
  /// The edition of the audiobook.
  public let edition: String?
  /// Whether or not the audiobook has explicit content.
  public let explicit: Bool
  /// Known external URLs for this audiobook.
  public let externalUrls: SpotifyExternalUrls
  /// A link to the Web API endpoint providing full details of the audiobook.
  public let href: URL
  /// The Spotify ID for the audiobook.
  public let id: String
  /// The cover art for the audiobook in various sizes.
  public let images: [SpotifyImage]
  /// A list of the languages used in the audiobook (ISO 639 codes).
  public let languages: [String]
  /// The media type of the audiobook.
  public let mediaType: String
  /// The name of the audiobook.
  public let name: String
  /// The narrator(s) for the audiobook.
  public let narrators: [Narrator]
  /// The publisher of the audiobook.
  public let publisher: String
  /// The object type (always "audiobook").
  public let type: SpotifyObjectType
  /// The Spotify URI for the audiobook.
  public let uri: String
  /// The number of chapters in this audiobook.
  public let totalChapters: Int
}

/// Audiobook author information.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
public struct Author: Codable, Sendable, Equatable {
  /// The name of the author.
  public let name: String
}

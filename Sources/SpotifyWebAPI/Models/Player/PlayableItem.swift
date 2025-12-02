import Foundation

/// A playable item in the Spotify catalog.
///
/// Represents content that can be played through the Spotify player,
/// such as tracks or podcast episodes.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
public enum PlayableItem: Codable, Sendable, Equatable {
  /// A music track.
  case track(Track)

  /// A podcast episode.
  case episode(Episode)
}

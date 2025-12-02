import Foundation

/// A Saved Episode Object (from user's library).
///
/// Source: `GET /v1/me/episodes`
public struct SavedEpisode: SavedItem {
  /// The date and time the episode was saved.
  public let addedAt: Date

  /// Information about the episode.
  public let episode: Episode

  public var content: Episode { episode }
}

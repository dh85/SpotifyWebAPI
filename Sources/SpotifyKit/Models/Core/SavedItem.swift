import Foundation

/// A protocol representing a saved item in the user's Spotify library.
///
/// Conforms to this protocol to provide a unified interface for saved items
/// across different content types (albums, tracks, shows, episodes, audiobooks).
public protocol SavedItem: Codable, Sendable, Equatable {
  /// The type of content being saved (e.g., Album, Track, Episode).
  associatedtype Content: Codable & Sendable & Equatable

  /// The date and time when the item was saved to the library.
  var addedAt: Date { get }

  /// The saved content (album, track, show, episode, or audiobook).
  var content: Content { get }
}

extension SavedItem {
  /// Returns true if this item was added after the specified date.
  public func wasAddedAfter(_ date: Date) -> Bool {
    addedAt > date
  }

  /// Returns true if this item was added before the specified date.
  public func wasAddedBefore(_ date: Date) -> Bool {
    addedAt < date
  }
}

/// Helper methods for working with collections of saved items.
extension Collection where Element: SavedItem {
  /// Returns saved items sorted by added date (most recent first).
  public func sortedByAddedDate(ascending: Bool = false) -> [Element] {
    sorted { ascending ? $0.addedAt < $1.addedAt : $0.addedAt > $1.addedAt }
  }

  /// Returns saved items added within the specified date range.
  public func addedBetween(_ startDate: Date, and endDate: Date) -> [Element] {
    filter { $0.addedAt >= startDate && $0.addedAt <= endDate }
  }

  /// Returns saved items added after the specified date.
  public func addedAfter(_ date: Date) -> [Element] {
    filter { $0.addedAt > date }
  }

  /// Returns saved items added before the specified date.
  public func addedBefore(_ date: Date) -> [Element] {
    filter { $0.addedAt < date }
  }
}

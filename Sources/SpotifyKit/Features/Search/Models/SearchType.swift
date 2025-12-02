import Foundation

/// The type of item to search for.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/search)
public enum SearchType: String, Sendable, Equatable, CaseIterable {
  /// Search for albums.
  case album
  /// Search for artists.
  case artist
  /// Search for playlists.
  case playlist
  /// Search for tracks.
  case track
  /// Search for shows (podcasts).
  case show
  /// Search for episodes.
  case episode
  /// Search for audiobooks.
  case audiobook
}

extension Set where Element == SearchType {
  /// Creates the comma-separated list Spotify expects for the 'type' query.
  var spotifyQueryValue: String {
    map(\.rawValue).sorted().joined(separator: ",")
  }
}

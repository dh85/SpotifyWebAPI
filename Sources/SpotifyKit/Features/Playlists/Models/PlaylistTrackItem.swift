import Foundation

/// A playlist track object containing information about a track or episode in a playlist.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
public struct PlaylistTrackItem: Codable, Sendable, Equatable {
  /// The date and time the track or episode was added.
  public let addedAt: Date?
  /// The Spotify user who added the track or episode.
  public let addedBy: SpotifyPublicUser?
  /// Whether this track or episode is a local file or not.
  public let isLocal: Bool
  /// Information about the track or episode.
  public let track: PlaylistTrack?
  
  /// The name of the track or episode, or nil if track is nil.
  public var name: String? {
    switch track {
    case .track(let t): return t.name
    case .episode(let e): return e.name
    case nil: return nil
    }
  }
  
  /// Comma-separated artist names for tracks, or show name for episodes, or nil if track is nil.
  public var artistNames: String? {
    switch track {
    case .track(let t): return t.artistNames
    case .episode(let e): return e.show?.name
    case nil: return nil
    }
  }
  
  /// The Spotify URI, or nil if track is nil.
  public var uri: String? {
    switch track {
    case .track(let t): return t.uri
    case .episode(let e): return e.uri
    case nil: return nil
    }
  }
  
  /// Returns the track if this item contains a track, nil otherwise.
  public var asTrack: Track? {
    guard case .track(let track) = track else { return nil }
    return track
  }
  
  /// Returns the episode if this item contains an episode, nil otherwise.
  public var asEpisode: Episode? {
    guard case .episode(let episode) = track else { return nil }
    return episode
  }
}

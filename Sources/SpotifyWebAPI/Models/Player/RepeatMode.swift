import Foundation

/// The repeat mode for playback.
public enum RepeatMode: String, Codable, Sendable, Equatable, CaseIterable {
  /// Repeat the current track.
  case track

  /// Repeat the current context (e.g., album, playlist).
  case context

  /// Repeat is off.
  case off
}

import Foundation

/// A Saved Track Object (from user's Liked Songs).
///
/// Source: `GET /v1/me/tracks`
public struct SavedTrack: Codable, Sendable, Equatable {
  /// The date and time the track was saved.
  public let addedAt: Date

  /// Information about the track.
  public let track: Track
}

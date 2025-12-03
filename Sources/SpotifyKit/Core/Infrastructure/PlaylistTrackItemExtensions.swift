import Foundation

extension Array where Element == PlaylistTrackItem {
  /// Total duration of all tracks in milliseconds.
  public var totalDurationMs: Int {
    compactMap { item -> Int? in
      guard let track = item.asTrack else { return nil }
      return track.durationMs
    }.reduce(0, +)
  }
}

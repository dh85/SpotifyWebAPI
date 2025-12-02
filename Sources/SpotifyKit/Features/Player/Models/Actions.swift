import Foundation

/// Actions that are currently disallowed for playback.
///
/// Each property indicates whether a specific action is disallowed.
/// `true` means the action is disallowed, `false` or `nil` means it's allowed.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
public struct Actions: Codable, Sendable, Equatable {
  public let interruptingPlayback: Bool?
  public let pausing: Bool?
  public let resuming: Bool?
  public let seeking: Bool?
  public let skippingNext: Bool?
  public let skippingPrev: Bool?
  public let togglingRepeatContext: Bool?
  public let togglingShuffle: Bool?
  public let togglingRepeatTrack: Bool?
  public let transferringPlayback: Bool?
}

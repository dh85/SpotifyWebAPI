import Foundation

/// A Spotify Connect device.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
public struct SpotifyDevice: Codable, Sendable, Equatable {
  /// The device ID. `nil` if the device is not available.
  public let id: String?

  /// Whether this device is the currently active device.
  public let isActive: Bool

  /// Whether the device is in a private session.
  public let isPrivateSession: Bool

  /// Whether controlling this device is restricted.
  public let isRestricted: Bool

  /// The name of the device.
  public let name: String

  /// The device type, such as "computer", "smartphone", or "speaker".
  public let type: String

  /// The current volume in percent (0-100). `nil` if not available.
  public let volumePercent: Int?

  /// Whether this device supports volume control. `nil` if not available.
  public let supportsVolume: Bool?
}

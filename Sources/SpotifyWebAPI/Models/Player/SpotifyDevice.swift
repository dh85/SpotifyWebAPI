import Foundation

/// A Spotify Connect device.
public struct SpotifyDevice: Codable, Sendable, Equatable {
    public let id: String?
    public let isActive: Bool
    public let isPrivateSession: Bool
    public let isRestricted: Bool
    public let name: String
    public let type: DeviceType

    /// The current volume in percent (0-100).
    public let volumePercent: Int?

    /// Whether this device supports volume control.
    public let supportsVolume: Bool?
}

extension SpotifyDevice {
    public enum DeviceType: String, Codable, Sendable {
        case computer = "computer"
        case smartphone = "smartphone"
        case speaker = "speaker"
    }
}

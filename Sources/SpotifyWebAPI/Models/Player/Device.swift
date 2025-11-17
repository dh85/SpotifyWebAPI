import Foundation

/// A Spotify Connect device.
public struct Device: Codable, Sendable, Equatable {
    public let id: String?
    public let isActive: Bool
    public let isPrivateSession: Bool
    public let isRestricted: Bool
    public let name: String

    /// The type of device (e.g., "computer", "smartphone", "speaker").
    public let type: String

    /// The current volume in percent (0-100).
    public let volumePercent: Int?

    /// Whether this device supports volume control.
    public let supportsVolume: Bool?
}

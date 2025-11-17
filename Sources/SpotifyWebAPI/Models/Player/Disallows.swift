import Foundation

/// The 'disallows' object, part of the Actions object.
///
/// Details which actions are currently disallowed. `true` means disallowed.
public struct Disallows: Codable, Sendable, Equatable {
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

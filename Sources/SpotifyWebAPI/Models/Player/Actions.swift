import Foundation

/// The 'actions' object, part of the PlaybackState.
public struct Actions: Codable, Sendable, Equatable {
    /// The set of actions that are currently disallowed.
    public let disallows: Disallows
}

import Foundation

/// Represents the user's last known playback position in an episode.
///
/// Requires the `user-read-playback-position` scope.
public struct ResumePoint: Codable, Sendable, Equatable {
    /// Whether or not the episode has been fully played by the user.
    public let fullyPlayed: Bool

    /// The user's last known position in the episode (in milliseconds).
    public let resumePositionMs: Int
}

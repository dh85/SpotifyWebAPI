import Foundation

/// A Saved Episode Object (from user's library).
///
/// Source: `GET /v1/me/episodes`
public struct SavedEpisode: Codable, Sendable, Equatable {
    /// The date and time the episode was saved.
    public let addedAt: Date

    /// Information about the episode.
    public let episode: Episode
}

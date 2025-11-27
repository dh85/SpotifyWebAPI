import Foundation

/// A play history item from the user's recently played tracks.
///
/// Represents a single track that was played, including when it was played
/// and the context it was played from.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-recently-played)
public struct PlayHistoryItem: Codable, Sendable, Equatable {
    /// The track that was played.
    public let track: Track

    /// The date and time the track was played (ISO 8601 format).
    public let playedAt: Date

    /// The context from which the track was played (e.g., playlist, album).
    public let context: PlaybackContext?
}

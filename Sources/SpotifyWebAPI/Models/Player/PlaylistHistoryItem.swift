import Foundation

/// A Play History Object (from user's recently played).
///
/// Source: `GET /v1/me/player/recently-played`
public struct PlayHistoryItem: Codable, Sendable, Equatable {
    /// The track the user listened to.
    public let track: Track

    /// The date and time the track was played.
    public let playedAt: Date

    /// The context the track was played from.
    public let context: PlaybackContext?

    enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
        case context
    }
}

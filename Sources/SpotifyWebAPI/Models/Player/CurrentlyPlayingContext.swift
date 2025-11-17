import Foundation

/// The user's currently playing context.
///
/// Source: `GET /v1/me/player/currently-playing`
public struct CurrentlyPlayingContext: Decodable, Sendable, Equatable {
    // Note: This model omits the 'device' field, which is
    // present in the full 'PlaybackState' model.

    public let context: PlaybackContext?
    public let timestamp: Date
    public let progressMs: Int?
    public let isPlaying: Bool
    public let item: PlayableItem?
    public let currentlyPlayingType: String
    public let actions: Actions

    // Define coding keys to match the snake_case JSON
    enum CodingKeys: String, CodingKey {
        case context, actions, item
        case timestamp
        case progressMs = "progress_ms"
        case isPlaying = "is_playing"
        case currentlyPlayingType = "currently_playing_type"
    }

    // Custom decoder (copied from PlaybackState, 'device' removed)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.context = try container.decodeIfPresent(
            PlaybackContext.self,
            forKey: .context
        )
        self.progressMs = try container.decodeIfPresent(
            Int.self,
            forKey: .progressMs
        )
        self.isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
        self.actions = try container.decode(Actions.self, forKey: .actions)
        self.currentlyPlayingType = try container.decode(
            String.self,
            forKey: .currentlyPlayingType
        )

        // Convert timestamp (Int64 milliseconds) to Date
        let timestampMs = try container.decode(Int64.self, forKey: .timestamp)
        self.timestamp = Date(
            timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0
        )

        // Handle the polymorphic 'item' based on 'currentlyPlayingType'
        switch self.currentlyPlayingType {
        case "track":
            self.item = .track(try container.decode(Track.self, forKey: .item))
        case "episode":
            self.item = .episode(
                try container.decode(Episode.self, forKey: .item)
            )
        default:
            self.item = nil
        }
    }
}

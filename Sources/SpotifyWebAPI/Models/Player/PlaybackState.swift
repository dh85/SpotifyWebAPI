import Foundation

/// The user's current playback state.
///
/// Source: `GET /v1/me/player`
public struct PlaybackState: Decodable, Sendable, Equatable {
    public let device: Device
    public let repeatState: String
    public let shuffleState: Bool
    public let context: PlaybackContext?
    public let timestamp: Date
    public let progressMs: Int?
    public let isPlaying: Bool
    public let item: PlayableItem?
    public let currentlyPlayingType: String
    public let actions: Actions

    // Define coding keys to match the snake_case JSON
    enum CodingKeys: String, CodingKey {
        case device, context, actions, item
        case repeatState = "repeat_state"
        case shuffleState = "shuffle_state"
        case timestamp
        case progressMs = "progress_ms"
        case isPlaying = "is_playing"
        case currentlyPlayingType = "currently_playing_type"
    }

    // Custom decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode standard properties
        self.device = try container.decode(Device.self, forKey: .device)
        self.repeatState = try container.decode(
            String.self,
            forKey: .repeatState
        )
        self.shuffleState = try container.decode(
            Bool.self,
            forKey: .shuffleState
        )
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

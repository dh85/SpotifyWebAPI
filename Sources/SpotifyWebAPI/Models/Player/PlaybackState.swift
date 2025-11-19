import Foundation

/// The user's current playback state.
///
/// Source: `GET /v1/me/player`
public struct PlaybackState: Decodable, Sendable, Equatable {
    public let device: SpotifyDevice
    public let repeatState: RepeatState
    public let shuffleState: Bool
    public let context: PlaybackContext?
    public let timestamp: Date
    public let progressMs: Int?
    public let isPlaying: Bool
    public let item: PlayableItem?
    public let currentlyPlayingType: CurrentlyPlayingType
    public let actions: Actions

    // Define coding keys to match the snake_case JSON
    enum CodingKeys: String, CodingKey {
        case device, context, actions, item
        case repeatState
        case shuffleState
        case timestamp
        case progressMs
        case isPlaying
        case currentlyPlayingType
    }

    // Custom decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode standard properties
        self.device = try container.decode(SpotifyDevice.self, forKey: .device)
        self.repeatState = try container.decode(
            RepeatState.self,
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
            CurrentlyPlayingType.self,
            forKey: .currentlyPlayingType
        )

        // Convert timestamp (Int64 milliseconds) to Date
        let timestampMs = try container.decode(Int64.self, forKey: .timestamp)
        self.timestamp = Date(
            timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0
        )

        // Handle the polymorphic 'item' based on 'currentlyPlayingType'
        switch self.currentlyPlayingType {
        case .track:
            self.item = .track(try container.decode(Track.self, forKey: .item))
        case .episode:
            self.item = .episode(
                try container.decode(Episode.self, forKey: .item)
            )
        default:
            self.item = nil
        }
    }
}

extension PlaybackState {
    public enum RepeatState: String, Codable, Sendable {
        case off = "off"
        case track = "track"
        case context = "context"
    }

    public enum CurrentlyPlayingType: String, Codable, Sendable {
        case track = "track"
        case episode = "episode"
        case ad = "ad"
        case unknown = "unknown"
    }
}

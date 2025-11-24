import Foundation

/// Information about the user's current playback.
///
/// This model represents the currently playing track or episode, including playback state
/// and context information. Note that some fields like `device`, `repeatState`, and
/// `shuffleState` may not be present depending on the endpoint used.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track)
public struct CurrentlyPlayingContext: Decodable, Sendable, Equatable {
    /// The device that is currently active. May be `nil` in some contexts.
    public let device: SpotifyDevice?

    /// The repeat mode. May be `nil` in some contexts.
    public let repeatState: RepeatMode?

    /// Whether shuffle is on. May be `nil` in some contexts.
    public let shuffleState: Bool?

    /// The context from which the track is playing (e.g., playlist, album).
    public let context: PlaybackContext?

    /// Unix timestamp (in seconds) when the data was fetched.
    public let timestamp: Date

    /// Progress into the currently playing track or episode in milliseconds.
    public let progressMs: Int?

    /// Whether something is currently playing.
    public let isPlaying: Bool

    /// The currently playing track or episode.
    public let item: PlayableItem?

    /// The type of the currently playing item (e.g., "track", "episode", "ad").
    public let currentlyPlayingType: String

    /// Actions that are currently disallowed.
    public let actions: Actions

    enum CodingKeys: String, CodingKey {
        case device, repeatState, shuffleState, context, timestamp, progressMs, isPlaying, item,
            currentlyPlayingType, actions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.device = try container.decodeIfPresent(SpotifyDevice.self, forKey: .device)

        self.repeatState = try container.decodeIfPresent(
            RepeatMode.self,
            forKey: .repeatState
        )

        self.shuffleState = try container.decodeIfPresent(Bool.self, forKey: .shuffleState)

        self.context = try container.decodeIfPresent(
            PlaybackContext.self,
            forKey: .context
        )

        // Convert timestamp (Int64 milliseconds) to Date
        let timestampMs = try container.decode(Int64.self, forKey: .timestamp)
        self.timestamp = dateFromUnixMilliseconds(timestampMs)

        self.progressMs = try container.decodeIfPresent(
            Int.self,
            forKey: .progressMs
        )

        self.isPlaying = try container.decode(Bool.self, forKey: .isPlaying)

        self.currentlyPlayingType = try container.decode(
            String.self,
            forKey: .currentlyPlayingType
        )

        self.actions = try container.decode(Actions.self, forKey: .actions)

        // Handle the polymorphic 'item' based on 'currentlyPlayingType'
        self.item = try PlayableItem.decode(
            from: container,
            forKey: .item,
            typeString: currentlyPlayingType
        )
    }
}

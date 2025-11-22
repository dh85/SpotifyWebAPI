import Foundation

/// Service for controlling and retrieving information about Spotify playback.
///
/// ## Overview
///
/// PlayerService provides comprehensive playback control including:
/// - Playback state and currently playing track
/// - Play, pause, skip, seek controls
/// - Volume, shuffle, and repeat settings
/// - Queue management
/// - Device management and transfer
/// - Recently played tracks
///
/// ## Examples
///
/// ### Get Current Playback State
/// ```swift
/// if let state = try await client.player.state() {
///     print("Playing: \(state.item?.name ?? "Unknown")")
///     print("Progress: \(state.progressMs ?? 0)ms")
///     print("Device: \(state.device.name)")
///     print("Shuffle: \(state.shuffleState), Repeat: \(state.repeatState)")
/// } else {
///     print("Nothing playing")
/// }
/// ```
///
/// ### Control Playback
/// ```swift
/// // Play a playlist
/// try await client.player.play(
///     contextURI: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
/// )
///
/// // Play specific tracks
/// try await client.player.play(uris: [
///     "spotify:track:6rqhFgbbKwnb9MLmUQDhG6",
///     "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
/// ])
///
/// // Pause
/// try await client.player.pause()
///
/// // Skip to next
/// try await client.player.skipToNext()
///
/// // Seek to 1 minute
/// try await client.player.seek(to: 60000)
/// ```
///
/// ### Manage Queue
/// ```swift
/// // Add track to queue
/// try await client.player.addToQueue(
///     uri: "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
/// )
///
/// // Get queue
/// let queue = try await client.player.getQueue()
/// print("Currently playing: \(queue.currentlyPlaying?.name ?? "Unknown")")
/// print("Up next: \(queue.queue.count) tracks")
/// ```
///
/// ### Manage Devices
/// ```swift
/// // Get available devices
/// let devices = try await client.player.devices()
/// for device in devices {
///     print("\(device.name) (\(device.type)) - \(device.isActive ? "Active" : "Inactive")")
/// }
///
/// // Transfer playback to another device
/// if let device = devices.first {
///     try await client.player.transfer(to: device.id, play: true)
/// }
/// ```
///
/// ### Adjust Settings
/// ```swift
/// // Set volume to 50%
/// try await client.player.setVolume(50)
///
/// // Enable shuffle
/// try await client.player.setShuffle(true)
///
/// // Set repeat mode
/// try await client.player.setRepeatMode(.context)
/// ```
///
/// ### Get Recently Played
/// ```swift
/// let recent = try await client.player.recentlyPlayed(limit: 20)
/// for item in recent.items {
///     print("\(item.track.name) - played at \(item.playedAt)")
/// }
/// ```
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
public struct PlayerService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

extension PlayerService where Capability == UserAuthCapability {

    // MARK: - Playback State

    /// Retrieves information about the user's current playback state.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback)
    ///
    /// - Parameters:
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Item types to include in the response.
    /// - Returns: The current playback state, or `nil` if nothing is playing.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-read-playback-state`
    public func state(
        market: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil
    ) async throws -> PlaybackState? {
        var query: [URLQueryItem] = []
        if let market {
            query.append(.init(name: "market", value: market))
        }

        if let additionalTypes {
            let value = additionalTypes.map { $0.rawValue }.sorted().joined(separator: ",")
            query.append(.init(name: "additional_types", value: value))
        }

        let request = SpotifyRequest<PlaybackState>.get("/me/player", query: query)
        return try await client.requestOptionalJSON(PlaybackState.self, request: request)
    }

    /// Retrieves the user's currently playing track or episode.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track)
    ///
    /// - Parameters:
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Item types to include in the response.
    /// - Returns: The currently playing context, or `nil` if nothing is playing.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-read-currently-playing`
    public func currentlyPlaying(
        market: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil
    ) async throws -> CurrentlyPlayingContext? {
        var query: [URLQueryItem] = []
        if let market {
            query.append(.init(name: "market", value: market))
        }

        if let additionalTypes {
            let value = additionalTypes.map { $0.rawValue }.sorted().joined(separator: ",")
            query.append(.init(name: "additional_types", value: value))
        }

        let request = SpotifyRequest<CurrentlyPlayingContext>.get(
            "/me/player/currently-playing",
            query: query
        )
        return try await client.requestOptionalJSON(CurrentlyPlayingContext.self, request: request)
    }

    /// Retrieves information about the user's available Spotify Connect devices.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-users-available-devices)
    ///
    /// - Returns: An array of available devices.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-read-playback-state`
    public func devices() async throws -> [SpotifyDevice] {
        let request = SpotifyRequest<AvailableDevicesWrapper>.get("/me/player/devices")
        return try await client.perform(request).items
    }

    // MARK: - Playback Control

    /// Transfers playback to a new device.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/transfer-a-users-playback)
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to transfer playback to.
    ///   - play: Whether to start playback immediately on the new device.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func transfer(to deviceID: String, play: Bool? = nil) async throws {
        let body = TransferPlaybackBody(deviceIds: [deviceID], play: play)
        let request = SpotifyRequest<EmptyResponse>.put("/me/player", body: body)
        try await client.perform(request)
    }

    /// Resumes playback on the user's active device.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback)
    ///
    /// - Parameter deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func resume(deviceID: String? = nil) async throws {
        try await sendPlayRequest(deviceID: deviceID, body: .resume)
    }

    /// Starts playback of a context (album, playlist, or artist).
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback)
    ///
    /// - Parameters:
    ///   - contextURI: The Spotify URI of the context to play.
    ///   - deviceID: The ID of the device to target.
    ///   - offset: Where to start playback within the context.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func play(
        contextURI: String,
        deviceID: String? = nil,
        offset: PlaybackOffset? = nil
    ) async throws {
        try await sendPlayRequest(deviceID: deviceID, body: .context(contextURI, offset: offset))
    }

    /// Starts playback of specific tracks.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/start-a-users-playback)
    ///
    /// - Parameters:
    ///   - uris: An array of Spotify track URIs to play.
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func play(uris: [String], deviceID: String? = nil) async throws {
        try await sendPlayRequest(deviceID: deviceID, body: .tracks(uris))
    }

    /// Pauses playback on the user's active device.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/pause-a-users-playback)
    ///
    /// - Parameter deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func pause(deviceID: String? = nil) async throws {
        let query = makeDeviceQueryItems(deviceID)
        let request = SpotifyRequest<EmptyResponse>.put("/me/player/pause", query: query)
        try await client.perform(request)
    }

    /// Skips to the next track in the user's queue.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-next-track)
    ///
    /// - Parameter deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func skipToNext(deviceID: String? = nil) async throws {
        let query = makeDeviceQueryItems(deviceID)
        let request = SpotifyRequest<EmptyResponse>.post("/me/player/next", query: query)
        try await client.perform(request)
    }

    /// Skips to the previous track in the user's queue.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/skip-users-playback-to-previous-track)
    ///
    /// - Parameter deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func skipToPrevious(deviceID: String? = nil) async throws {
        let query = makeDeviceQueryItems(deviceID)
        let request = SpotifyRequest<EmptyResponse>.post("/me/player/previous", query: query)
        try await client.perform(request)
    }

    /// Seeks to a position in the currently playing track.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/seek-to-position-in-currently-playing-track)
    ///
    /// - Parameters:
    ///   - positionMs: The position in milliseconds to seek to (must be >= 0).
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails or position is negative.
    ///
    /// Required scope: `user-modify-playback-state`
    public func seek(to positionMs: Int, deviceID: String? = nil) async throws {
        guard positionMs >= 0 else {
            throw SpotifyClientError.invalidRequest(reason: "positionMs must be >= 0")
        }

        var query: [URLQueryItem] = [.init(name: "position_ms", value: String(positionMs))]
        query.append(contentsOf: makeDeviceQueryItems(deviceID))

        let request = SpotifyRequest<EmptyResponse>.put("/me/player/seek", query: query)
        try await client.perform(request)
    }

    /// Sets the repeat mode for playback.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/set-repeat-mode-on-users-playback)
    ///
    /// - Parameters:
    ///   - mode: The repeat mode (track, context, or off).
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func setRepeatMode(_ mode: RepeatMode, deviceID: String? = nil) async throws {
        var query: [URLQueryItem] = [.init(name: "state", value: mode.rawValue)]
        query.append(contentsOf: makeDeviceQueryItems(deviceID))

        let request = SpotifyRequest<EmptyResponse>.put("/me/player/repeat", query: query)
        try await client.perform(request)
    }

    /// Sets the volume for playback.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/set-volume-for-users-playback)
    ///
    /// - Parameters:
    ///   - percent: The volume to set (0-100).
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails or volume is out of range.
    ///
    /// Required scope: `user-modify-playback-state`
    public func setVolume(_ percent: Int, deviceID: String? = nil) async throws {
        guard (0...100).contains(percent) else {
            throw SpotifyClientError.invalidRequest(reason: "Volume must be between 0 and 100")
        }

        var query: [URLQueryItem] = [.init(name: "volume_percent", value: String(percent))]
        query.append(contentsOf: makeDeviceQueryItems(deviceID))

        let request = SpotifyRequest<EmptyResponse>.put("/me/player/volume", query: query)
        try await client.perform(request)
    }

    /// Toggles shuffle mode for playback.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/toggle-shuffle-for-users-playback)
    ///
    /// - Parameters:
    ///   - state: Whether to enable shuffle.
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func setShuffle(_ state: Bool, deviceID: String? = nil) async throws {
        var query: [URLQueryItem] = [.init(name: "state", value: String(state))]
        query.append(contentsOf: makeDeviceQueryItems(deviceID))

        let request = SpotifyRequest<EmptyResponse>.put("/me/player/shuffle", query: query)
        try await client.perform(request)
    }

    /// Get the list of objects that make up the user's queue.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-queue)
    ///
    /// - Returns: Information about the queue.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-read-playback-state` or `user-read-currently-playing`
    public func getQueue() async throws -> UserQueue {
        let request = SpotifyRequest<UserQueue>.get("/me/player/queue")
        return try await client.perform(request)
    }

    /// Adds a track or episode to the playback queue.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/add-to-queue)
    ///
    /// - Parameters:
    ///   - uri: The Spotify URI of the track or episode to add.
    ///   - deviceID: The ID of the device to target.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// Required scope: `user-modify-playback-state`
    public func addToQueue(uri: String, deviceID: String? = nil) async throws {
        var query: [URLQueryItem] = [.init(name: "uri", value: uri)]
        query.append(contentsOf: makeDeviceQueryItems(deviceID))

        let request = SpotifyRequest<EmptyResponse>.post("/me/player/queue", query: query)
        try await client.perform(request)
    }

    // MARK: - Recently Played

    /// Retrieves the user's recently played tracks.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-recently-played)
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50).
    ///   - after: Return items played after this timestamp.
    ///   - before: Return items played before this timestamp.
    /// - Returns: A cursor-based page of play history items.
    /// - Throws: `SpotifyError` if the request fails or parameters are invalid.
    ///
    /// Required scope: `user-read-recently-played`
    ///
    /// - Note: Only one of `after` or `before` can be specified, not both.
    public func recentlyPlayed(
        limit: Int = 20,
        after: Date? = nil,
        before: Date? = nil
    ) async throws -> CursorBasedPage<PlayHistoryItem> {
        try validateLimit(limit, withinRange: 1...50)

        if after != nil && before != nil {
            throw SpotifyClientError.invalidRequest(
                reason: "Cannot specify both 'after' and 'before'")
        }

        var query: [URLQueryItem] = [.init(name: "limit", value: String(limit))]

        if let after {
            query.append(.init(name: "after", value: String(dateToUnixMilliseconds(after))))
        }

        if let before {
            query.append(.init(name: "before", value: String(dateToUnixMilliseconds(before))))
        }

        let request = SpotifyRequest<CursorBasedPage<PlayHistoryItem>>.get(
            "/me/player/recently-played",
            query: query
        )
        return try await client.perform(request)
    }

    // MARK: - Private Helpers

    private func makeDeviceQueryItems(_ deviceID: String?) -> [URLQueryItem] {
        deviceID.map { [.init(name: "device_id", value: $0)] } ?? []
    }

    private func sendPlayRequest(deviceID: String?, body: StartPlaybackBody) async throws {
        let query = makeDeviceQueryItems(deviceID)
        let path = "/me/player/play"

        let isResumeOnly =
            body.contextUri == nil && body.uris == nil && body.offset == nil
            && body.positionMs == nil

        if isResumeOnly {
            let request = SpotifyRequest<EmptyResponse>.put(path, query: query)
            try await client.perform(request)
        } else {
            let request = SpotifyRequest<EmptyResponse>.put(path, query: query, body: body)
            try await client.perform(request)
        }
    }
}

// MARK: - Private Types

private struct StartPlaybackBody: Encodable, Sendable {
    let contextUri: String?
    let uris: [String]?
    let offset: PlaybackOffset?
    let positionMs: Int?

    enum CodingKeys: String, CodingKey {
        case contextUri = "context_uri"
        case uris
        case offset
        case positionMs = "position_ms"
    }

    static var resume: StartPlaybackBody {
        StartPlaybackBody(contextUri: nil, uris: nil, offset: nil, positionMs: nil)
    }

    static func context(
        _ uri: String,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(contextUri: uri, uris: nil, offset: offset, positionMs: positionMs)
    }

    static func tracks(_ uris: [String], positionMs: Int? = nil) -> StartPlaybackBody {
        StartPlaybackBody(contextUri: nil, uris: uris, offset: nil, positionMs: positionMs)
    }
}

private struct TransferPlaybackBody: Encodable, Sendable {
    let deviceIds: [String]
    let play: Bool?

    enum CodingKeys: String, CodingKey {
        case deviceIds = "device_ids"
        case play
    }
}

private typealias AvailableDevicesWrapper = ArrayWrapper<SpotifyDevice>

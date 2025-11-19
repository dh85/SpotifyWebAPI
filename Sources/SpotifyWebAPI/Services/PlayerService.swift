import Foundation

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

    /// Body for resuming playback.
    static var resume: StartPlaybackBody {
        StartPlaybackBody(
            contextUri: nil,
            uris: nil,
            offset: nil,
            positionMs: nil
        )
    }

    /// Body for playing a context (album, playlist, artist).
    static func context(
        _ uri: String,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(
            contextUri: uri,
            uris: nil,
            offset: offset,
            positionMs: positionMs
        )

    }

    /// Body for playing a list of tracks.
    static func tracks(
        _ uris: [String],
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(
            contextUri: nil,
            uris: uris,
            offset: nil,  // Offset is not valid for 'uris'
            positionMs: positionMs
        )
    }
}

// --- Transfer Playback Body (Encapsulated) ---
private struct TransferPlaybackBody: Encodable, Sendable {
    let deviceIds: [String]
    let play: Bool?

    enum CodingKeys: String, CodingKey {
        case deviceIds = "device_ids"
        case play
    }
}

private struct AvailableDevicesWrapper: Decodable { let devices: [SpotifyDevice] }

/// A service providing methods to control and retrieve information about the current user's Spotify playback.
public struct PlayerService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// Player endpoints require User Authentication
extension PlayerService where Capability == UserAuthCapability {

    /// Get information about the user's current playback state, including device, track, and context.
    ///
    /// Corresponds to: `GET /v1/me/player`
    /// Requires the `user-read-playback-state` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Optional. A list of item types to include in the response (e.g., "track", "episode").
    /// - Returns: A `PlaybackState` object, or `nil` if nothing is playing (204 No Content).
    public func state(
        market: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> PlaybackState? {
        var query: [URLQueryItem] = []

        if let market {
            query.append(.init(name: "market", value: market))
        }

        if let additionalTypes {
            let value = additionalTypes.joined(separator: ",")
            query.append(.init(name: "additional_types", value: value))
        }

        let request = SpotifyRequest<PlaybackState>.get(
            "/me/player",
            query: query
        )

        return try await client.requestOptionalJSON(
            PlaybackState.self,
            request: request
        )
    }

    /// Get the user's currently playing track or episode.
    ///
    /// Corresponds to: `GET /v1/me/player/currently-playing`
    /// Requires the `user-read-currently-playing` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Optional. A list of item types to include in the response (e.g., "track", "episode").
    /// - Returns: A `CurrentlyPlayingContext` object, or `nil` if nothing is playing (204 No Content).
    public func currentlyPlaying(
        market: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> CurrentlyPlayingContext? {

        var query: [URLQueryItem] = []

        if let market {
            query.append(.init(name: "market", value: market))
        }

        if let additionalTypes {
            // FIX: Simple conditional logic for the second parameter
            let value = additionalTypes.joined(separator: ",")
            query.append(.init(name: "additional_types", value: value))
        }

        let request = SpotifyRequest<CurrentlyPlayingContext>.get(
            "/me/player/currently-playing",
            query: query  // Pass the cleanly built array
        )

        return try await client.requestOptionalJSON(
            CurrentlyPlayingContext.self,
            request: request
        )
    }

    /// Get information about a user's available Spotify Connect devices.
    ///
    /// Corresponds to: `GET /v1/me/player/devices`
    /// Requires the `user-read-playback-state` scope.
    ///
    /// - Returns: A list of `Device` objects.
    public func devices() async throws -> [SpotifyDevice] {
        let request = SpotifyRequest<AvailableDevicesWrapper>.get(
            "/me/player/devices"
        )
        return try await client.perform(request).devices
    }

    /// Transfer playback to a new device.
    ///
    /// Corresponds to: `PUT /v1/me/player`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to transfer to.
    ///   - play: If `true`, playback will start immediately on the new device.
    public func transfer(to deviceID: String, play: Bool? = nil) async throws {
        let body = TransferPlaybackBody(deviceIds: [deviceID], play: play)
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player",
            body: body
        )
        try await client.perform(request)
    }

    /// Resume the user's current playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/play` (with empty body)
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func resume(deviceID: String? = nil) async throws {
        try await sendPlayRequest(deviceID: deviceID, body: .resume)
    }

    /// Start playback of a specific context (e.g., album, playlist, artist).
    ///
    /// Corresponds to: `PUT /v1/me/player/play`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - contextURI: The URI of the context to play.
    ///   - deviceID: Optional. The ID of the device to target.
    ///   - offset: Optional. Where to start playback (by position or URI).
    public func play(
        contextURI: String,
        deviceID: String? = nil,
        offset: PlaybackOffset? = nil
    ) async throws {
        try await sendPlayRequest(
            deviceID: deviceID,
            body: .context(contextURI, offset: offset)
        )
    }

    /// Start playback of specific tracks.
    ///
    /// Corresponds to: `PUT /v1/me/player/play`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - uris: A list of track URIs to play.
    ///   - deviceID: Optional. The ID of the device to target.
    public func play(uris: [String], deviceID: String? = nil) async throws {
        try await sendPlayRequest(deviceID: deviceID, body: .tracks(uris))
    }

    /// Pause the user's current playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/pause`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func pause(deviceID: String? = nil) async throws {
        let query: [URLQueryItem] =
            deviceID.map { [.init(name: "device_id", value: $0)] } ?? []
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player/pause",
            query: query
        )
        try await client.perform(request)
    }

    /// Skip to the next track or episode in the user's queue.
    ///
    /// Corresponds to: `POST /v1/me/player/next`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func skipToNext(deviceID: String? = nil) async throws {
        let query: [URLQueryItem] =
            deviceID.map { [.init(name: "device_id", value: $0)] } ?? []
        let request = SpotifyRequest<EmptyResponse>.post(
            "/me/player/next",
            query: query
        )
        try await client.perform(request)
    }

    /// Skip to the previous track or episode in the user's queue.
    ///
    /// Corresponds to: `POST /v1/me/player/previous`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func skipToPrevious(deviceID: String? = nil) async throws {
        let query: [URLQueryItem] =
            deviceID.map { [.init(name: "device_id", value: $0)] } ?? []
        let request = SpotifyRequest<EmptyResponse>.post(
            "/me/player/previous",
            query: query
        )
        try await client.perform(request)
    }

    /// Seek to a position in the user's currently playing track.
    ///
    /// Corresponds to: `PUT /v1/me/player/seek`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - positionMs: The position in milliseconds to seek to.
    ///   - deviceID: Optional. The ID of the device to target.
    public func seek(to positionMs: Int, deviceID: String? = nil) async throws {
        var query: [URLQueryItem] = [
            .init(name: "position_ms", value: String(positionMs))
        ]
        if let deviceID {
            query.append(.init(name: "device_id", value: deviceID))
        }
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player/seek",
            query: query
        )
        try await client.perform(request)
    }

    /// Set the repeat mode for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/repeat`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - mode: The repeat mode (`.track`, `.context`, or `.off`).
    ///   - deviceID: Optional. The ID of the device to target.
    public func setRepeatMode(_ mode: RepeatMode, deviceID: String? = nil)
        async throws
    {
        var query: [URLQueryItem] = [.init(name: "state", value: mode.rawValue)]
        if let deviceID {
            query.append(.init(name: "device_id", value: deviceID))
        }
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player/repeat",
            query: query
        )
        try await client.perform(request)
    }

    /// Set the volume for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/volume`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - percent: The volume to set (integer 0...100).
    ///   - deviceID: Optional. The ID of the device to target.
    public func setVolume(_ percent: Int, deviceID: String? = nil) async throws
    {
        var query: [URLQueryItem] = [
            .init(
                name: "volume_percent",
                value: String(min(max(percent, 0), 100))
            )
        ]
        if let deviceID {
            query.append(.init(name: "device_id", value: deviceID))
        }
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player/volume",
            query: query
        )
        try await client.perform(request)
    }

    /// Toggle shuffle mode for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/shuffle`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - state: `true` to turn shuffle on, `false` to turn it off.
    ///   - deviceID: Optional. The ID of the device to target.
    public func setShuffle(_ state: Bool, deviceID: String? = nil) async throws
    {
        var query: [URLQueryItem] = [.init(name: "state", value: String(state))]
        if let deviceID {
            query.append(.init(name: "device_id", value: deviceID))
        }
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/player/shuffle",
            query: query
        )
        try await client.perform(request)
    }

    /// Add a track or episode to the user's playback queue.
    ///
    /// Corresponds to: `POST /v1/me/player/queue`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - uri: The Spotify URI of the track or episode to add.
    ///   - deviceID: Optional. The ID of the device to target.
    public func addToQueue(uri: String, deviceID: String? = nil) async throws {
        var query: [URLQueryItem] = [.init(name: "uri", value: uri)]
        if let deviceID {
            query.append(.init(name: "device_id", value: deviceID))
        }
        let request = SpotifyRequest<EmptyResponse>.post(
            "/me/player/queue",
            query: query
        )
        try await client.perform(request)
    }

    /// Get the user's recently played tracks.
    ///
    /// Corresponds to: `GET /v1/me/player/recently-played`
    /// Requires the `user-read-recently-played` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: Optional. A timestamp (Date) to return items *after*.
    ///   - before: Optional. A timestamp (Date) to return items *before*.
    /// - Returns: A `CursorBasedPage` of `PlayHistoryItem` objects.
    public func recentlyPlayed(
        limit: Int = 20,
        after: Date? = nil,
        before: Date? = nil
    ) async throws -> CursorBasedPage<PlayHistoryItem> {
        let afterMs = after.map { Int64($0.timeIntervalSince1970 * 1000) }
        let beforeMs = before.map { Int64($0.timeIntervalSince1970 * 1000) }

        var query: [URLQueryItem] = [.init(name: "limit", value: String(limit))]
        if let afterMs {
            query.append(.init(name: "after", value: String(afterMs)))
        }
        if let beforeMs {
            query.append(.init(name: "before", value: String(beforeMs)))
        }

        let request = SpotifyRequest<CursorBasedPage<PlayHistoryItem>>.get(
            "/me/player/recently-played",
            query: query
        )
        return try await client.perform(request)
    }

    // Private helper to keep the public API clean
    private func sendPlayRequest(deviceID: String?, body: StartPlaybackBody)
        async throws
    {
        let query: [URLQueryItem] =
            deviceID.map { [.init(name: "device_id", value: $0)] } ?? []

        let path = "/me/player/play"

        let isResumeOnly =
            body.contextUri == nil && body.uris == nil && body.offset == nil
            && body.positionMs == nil

        if isResumeOnly {
            let request = SpotifyRequest<EmptyResponse>.put(
                path,  // Use constant path
                query: query
            )
            try await client.perform(request)
        } else {
            let request = SpotifyRequest<EmptyResponse>.put(
                path,  // Use constant path
                query: query,
                body: body
            )
            try await client.perform(request)
        }
    }
}

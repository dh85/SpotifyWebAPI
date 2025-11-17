import Foundation

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get the user's current playback state, including device, track, and
    /// play context.
    ///
    /// Corresponds to: `GET /v1/me/player`
    /// Requires the `user-read-playback-state` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Optional. A list of types to include
    ///     (e.g., "track", "episode").
    /// - Returns: A `PlaybackState` object if a track is playing, or
    ///   `nil` if no track is playing (204 No Content).
    public func playbackState(
        market: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> PlaybackState? {

        let endpoint = PlayerEndpoint.getPlaybackState(
            market: market,
            additionalTypes: additionalTypes
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Use the low-level authorizedRequest to check the status code
        let (data, response) = try await authorizedRequest(url: url)

        // 204 No Content means nothing is playing
        if response.statusCode == 204 {
            return nil
        }

        // Check for other errors
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // If 200 OK, decode the full state
        return try decodeJSON(PlaybackState.self, from: data)
    }

    /// Transfer playback to a new device.
    ///
    /// Corresponds to: `PUT /v1/me/player`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to transfer to.
    ///   - play: If `true`, playback will start immediately.
    ///           If `false` or `nil`, the new device will be paused.
    public func transferPlayback(
        to deviceID: String,
        play: Bool? = nil
    ) async throws {

        let endpoint = PlayerEndpoint.transferPlayback()
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body. The API expects an array of device IDs,
        // but for a transfer, it only ever contains one.
        let body = TransferPlaybackBody(
            deviceIds: [deviceID],
            play: play
        )
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized PUT request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
            body: httpBody,
            contentType: "application/json"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Get information about a user's available devices.
    ///
    /// Corresponds to: `GET /v1/me/player/devices`
    /// Requires the `user-read-playback-state` scope.
    ///
    /// - Returns: A list of `Device` objects.
    public func availableDevices() async throws -> [Device] {

        let endpoint = PlayerEndpoint.getAvailableDevices()
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            AvailableDevicesResponse.self,
            url: url
        )

        // Return the unwrapped array
        return response.devices
    }

    /// Get the user's currently playing track or episode.
    ///
    /// Corresponds to: `GET /v1/me/player/currently-playing`
    /// Requires the `user-read-currently-playing` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Optional. A list of types to include
    ///     (e.g., "track", "episode").
    /// - Returns: A `CurrentlyPlayingContext` object if a track is playing,
    ///   or `nil` if no track is playing (204 No Content).
    public func currentlyPlaying(
        market: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> CurrentlyPlayingContext? {

        let endpoint = PlayerEndpoint.getCurrentlyPlaying(
            market: market,
            additionalTypes: additionalTypes
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Use the low-level authorizedRequest to check the status code
        let (data, response) = try await authorizedRequest(url: url)

        // 204 No Content means nothing is playing
        if response.statusCode == 204 {
            return nil
        }

        // Check for other errors
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // If 200 OK, decode the context
        return try decodeJSON(CurrentlyPlayingContext.self, from: data)
    }

    // MARK: - Start/Resume Playback

    /// Internal helper to send a `PUT` request to the `/play` endpoint.
    private func sendPlaybackRequest(
        deviceID: String? = nil,
        body: StartPlaybackBody
    ) async throws {
        let endpoint = PlayerEndpoint.startPlayback(deviceID: deviceID)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Only encode body if it's not a simple resume
        let httpBody =
            (body.contextUri == nil && body.uris == nil && body.offset == nil
                && body.positionMs == nil)
            ? nil
            : try JSONEncoder().encode(body)

        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
            body: httpBody,
            contentType: httpBody != nil ? "application/json" : nil
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Resume the user's current playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/play` (with empty body)
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func resumePlayback(deviceID: String? = nil) async throws {
        try await sendPlaybackRequest(
            deviceID: deviceID,
            body: .resume
        )
    }

    /// Start playback of a context (e.g., album, playlist, artist).
    ///
    /// Corresponds to: `PUT /v1/me/player/play`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - contextURI: The URI of the context to play.
    ///   - deviceID: Optional. The ID of the device to target.
    ///   - offset: Optional. Where to start playback (by position or URI).
    ///   - positionMs: Optional. The position (in ms) to seek to.
    public func startPlayback(
        contextURI: String,
        deviceID: String? = nil,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) async throws {
        try await sendPlaybackRequest(
            deviceID: deviceID,
            body: .context(
                contextURI,
                offset: offset,
                positionMs: positionMs
            )
        )
    }

    /// Start playback of one or more tracks.
    ///
    /// Corresponds to: `PUT /v1/me/player/play`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - trackURIs: A list of track URIs to play.
    ///   - deviceID: Optional. The ID of the device to target.
    ///   - positionMs: Optional. The position (in ms) to seek to.
    public func startPlayback(
        trackURIs: [String],
        deviceID: String? = nil,
        positionMs: Int? = nil
    ) async throws {
        guard !trackURIs.isEmpty else { return }  // Don't send empty array

        try await sendPlaybackRequest(
            deviceID: deviceID,
            body: .tracks(trackURIs, positionMs: positionMs)
        )
    }

    // MARK: - Pause Playback

    /// Pause the user's current playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/pause`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func pausePlayback(deviceID: String? = nil) async throws {

        let endpoint = PlayerEndpoint.pausePlayback(deviceID: deviceID)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Skip To Next

    /// Skip to the next track in the user's queue.
    ///
    /// Corresponds to: `POST /v1/me/player/next`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func skipToNext(deviceID: String? = nil) async throws {

        let endpoint = PlayerEndpoint.skipToNext(deviceID: deviceID)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized POST request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "POST"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Skip To Previous

    /// Skip to the previous track in the user's queue.
    ///
    /// Corresponds to: `POST /v1/me/player/previous`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameter deviceID: Optional. The ID of the device to target.
    public func skipToPrevious(deviceID: String? = nil) async throws {

        let endpoint = PlayerEndpoint.skipToPrevious(deviceID: deviceID)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized POST request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "POST"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Seek To Position

    /// Seek to a position in the user's currently playing track.
    ///
    /// Corresponds to: `PUT /v1/me/player/seek`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - positionMs: The position in milliseconds to seek to.
    ///   - deviceID: Optional. The ID of the device to target.
    public func seekToPosition(
        _ positionMs: Int,
        deviceID: String? = nil
    ) async throws {

        let endpoint = PlayerEndpoint.seekToPosition(
            positionMs: positionMs,
            deviceID: deviceID
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Set Repeat Mode

    /// Set the repeat mode for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/repeat`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - state: The repeat mode (`.track`, `.context`, or `.off`).
    ///   - deviceID: Optional. The ID of the device to target.
    public func setRepeatMode(
        _ state: RepeatMode,
        deviceID: String? = nil
    ) async throws {

        let endpoint = PlayerEndpoint.setRepeatMode(
            state: state,
            deviceID: deviceID
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Set Playback Volume

    /// Set the volume for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/volume`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - volumePercent: The volume to set (integer 0...100).
    ///   - deviceID: Optional. The ID of the device to target.
    public func setPlaybackVolume(
        _ volumePercent: Int,
        deviceID: String? = nil
    ) async throws {

        // Clamp the value to Spotify's allowed range
        let clampedPercent = min(max(volumePercent, 0), 100)

        let endpoint = PlayerEndpoint.setPlaybackVolume(
            volumePercent: clampedPercent,
            deviceID: deviceID
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Set Playback Shuffle

    /// Toggle shuffle mode for the user's playback.
    ///
    /// Corresponds to: `PUT /v1/me/player/shuffle`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - state: `true` to turn shuffle on, `false` to turn it off.
    ///   - deviceID: Optional. The ID of the device to target.
    public func setPlaybackShuffle(
        _ state: Bool,
        deviceID: String? = nil
    ) async throws {

        let endpoint = PlayerEndpoint.setPlaybackShuffle(
            state: state,
            deviceID: deviceID
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    // MARK: - Get Recently Played

    /// Get the user's recently played tracks.
    ///
    /// Corresponds to: `GET /v1/me/player/recently-played`
    /// Requires the `user-read-recently-played` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: A `Date` for a timestamp to return items *after*.
    ///   - before: A `Date` for a timestamp to return items *before*.
    /// - Returns: A `CursorBasedPage` of `PlayHistoryItem` objects.
    public func recentlyPlayed(
        limit: Int = 20,
        after: Date? = nil,
        before: Date? = nil
    ) async throws -> CursorBasedPage<PlayHistoryItem> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        // Convert Dates to Unix timestamps in milliseconds (Int64)
        let afterMs = after.map { Int64($0.timeIntervalSince1970 * 1000) }
        let beforeMs = before.map { Int64($0.timeIntervalSince1970 * 1000) }

        let endpoint = PlayerEndpoint.getRecentlyPlayed(
            limit: clampedLimit,
            after: afterMs,
            before: beforeMs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(
            CursorBasedPage<PlayHistoryItem>.self,
            url: url
        )
    }

    // MARK: - Add Item to Queue

    /// Add a track or episode to the user's playback queue.
    ///
    /// Corresponds to: `POST /v1/me/player/queue`
    /// Requires the `user-modify-playback-state` scope.
    ///
    /// - Parameters:
    ///   - uri: The Spotify URI of the track or episode to add.
    ///   - deviceID: Optional. The ID of the device to target.
    public func addItemToQueue(
        uri: String,
        deviceID: String? = nil
    ) async throws {

        let endpoint = PlayerEndpoint.addItemToQueue(
            uri: uri,
            deviceID: deviceID
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized POST request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "POST"
        )

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }
}

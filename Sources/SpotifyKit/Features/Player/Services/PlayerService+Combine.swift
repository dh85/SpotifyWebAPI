#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror ``PlayerService`` async control and state APIs.
  ///
  /// ## Async Counterparts
  /// Call async helpers such as ``PlayerService/state(market:additionalTypes:)`` or
  /// ``PlayerService/play(contextURI:deviceID:offset:)`` when you prefer async/await—the
  /// publishers below simply wrap those implementations.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension PlayerService where Capability == UserAuthCapability {

    /// Retrieves information about the user's current playback state.
    ///
    /// - Parameters:
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Item types to include in the response.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the current playback state, or `nil` if nothing is playing.
    public func statePublisher(
      market: String? = nil,
      additionalTypes: Set<AdditionalItemType>? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<PlaybackState?, Error> {
      publisher(priority: priority) { service in
        try await service.state(market: market, additionalTypes: additionalTypes)
      }
    }

    /// Retrieves the user's currently playing track or episode.
    ///
    /// - Parameters:
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - additionalTypes: Item types to include in the response.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits the currently playing context, or `nil` if nothing is playing.
    public func currentlyPlayingPublisher(
      market: String? = nil,
      additionalTypes: Set<AdditionalItemType>? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<CurrentlyPlayingContext?, Error> {
      publisher(priority: priority) { service in
        try await service.currentlyPlaying(market: market, additionalTypes: additionalTypes)
      }
    }

    /// Retrieves information about the user's available Spotify Connect devices.
    ///
    /// - Parameter priority: The priority of the task.
    /// - Returns: A publisher that emits an array of available devices.
    public func devicesPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      [SpotifyDevice], Error
    > {
      publisher(priority: priority) { service in
        try await service.devices()
      }
    }

    /// Transfers playback to a new device.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to transfer playback to.
    ///   - play: Whether to start playback immediately on the new device.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func transferPublisher(
      to deviceID: String,
      play: Bool? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.transfer(to: deviceID, play: play)
      }
    }

    /// Resumes playback on the user's active device.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func resumePublisher(
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.resume(deviceID: deviceID)
      }
    }

    /// Starts playback of a context (album, playlist, or artist).
    ///
    /// - Parameters:
    ///   - contextURI: The Spotify URI of the context to play.
    ///   - deviceID: The ID of the device to target.
    ///   - offset: Where to start playback within the context.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func playPublisher(
      contextURI: String,
      deviceID: String? = nil,
      offset: PlaybackOffset? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.play(contextURI: contextURI, deviceID: deviceID, offset: offset)
      }
    }

    /// Starts playback of specific tracks.
    ///
    /// - Parameters:
    ///   - uris: An array of Spotify track URIs to play.
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func playPublisher(
      uris: [String],
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.play(uris: uris, deviceID: deviceID)
      }
    }

    /// Pauses playback on the user's active device.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func pausePublisher(
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.pause(deviceID: deviceID)
      }
    }

    /// Skips to the next track in the user's queue.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func skipToNextPublisher(
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.skipToNext(deviceID: deviceID)
      }
    }

    /// Skips to the previous track in the user's queue.
    ///
    /// - Parameters:
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func skipToPreviousPublisher(
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.skipToPrevious(deviceID: deviceID)
      }
    }

    /// Seeks to a specific position in the currently playing track.
    ///
    /// - Parameters:
    ///   - positionMs: The position to seek to, in milliseconds.
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func seekPublisher(
      to positionMs: Int,
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.seek(to: positionMs, deviceID: deviceID)
      }
    }

    /// Sets the repeat mode for playback.
    ///
    /// - Parameters:
    ///   - mode: The repeat mode to set.
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func setRepeatModePublisher(
      _ mode: RepeatMode,
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.setRepeatMode(mode, deviceID: deviceID)
      }
    }

    /// Sets the volume for playback.
    ///
    /// - Parameters:
    ///   - percent: The volume to set (0-100).
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func setVolumePublisher(
      _ percent: Int,
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.setVolume(percent, deviceID: deviceID)
      }
    }

    /// Toggles shuffle for playback.
    ///
    /// - Parameters:
    ///   - shuffle: Whether to enable shuffle.
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func setShufflePublisher(
      _ shuffle: Bool,
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.setShuffle(shuffle, deviceID: deviceID)
      }
    }

    /// Retrieves the user's recently played tracks.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: Return items played after this timestamp.
    ///   - before: Return items played before this timestamp.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of `PlayHistoryItem` values.
    public func recentlyPlayedPublisher(
      limit: Int = 20,
      after: Date? = nil,
      before: Date? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<CursorBasedPage<PlayHistoryItem>, Error> {
      publisher(priority: priority) { service in
        try await service.recentlyPlayed(limit: limit, after: after, before: before)
      }
    }

    /// Adds a track to the user's playback queue.
    ///
    /// - Parameters:
    ///   - uri: The Spotify URI of the track to add.
    ///   - deviceID: The ID of the device to target.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func addToQueuePublisher(
      uri: String,
      deviceID: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      publisher(priority: priority) { service in
        try await service.addToQueue(uri: uri, deviceID: deviceID)
      }
    }

    /// Retrieves the user's current playback queue.
    ///
    /// - Parameter priority: The priority of the task.
    /// - Returns: A publisher that emits the current queue.
    public func queuePublisher(
      priority: TaskPriority? = nil
    ) -> AnyPublisher<UserQueue, Error> {
      publisher(priority: priority) { service in
        try await service.queue()
      }
    }
  }

#endif

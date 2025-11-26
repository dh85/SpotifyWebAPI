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

        public func statePublisher(
            market: String? = nil,
            additionalTypes: Set<AdditionalItemType>? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<PlaybackState?, Error> {
            publisher(priority: priority) { service in
                try await service.state(market: market, additionalTypes: additionalTypes)
            }
        }

        public func currentlyPlayingPublisher(
            market: String? = nil,
            additionalTypes: Set<AdditionalItemType>? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<CurrentlyPlayingContext?, Error> {
            publisher(priority: priority) { service in
                try await service.currentlyPlaying(market: market, additionalTypes: additionalTypes)
            }
        }

        public func devicesPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
            [SpotifyDevice], Error
        > {
            publisher(priority: priority) { service in
                try await service.devices()
            }
        }

        public func transferPublisher(
            to deviceID: String,
            play: Bool? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.transfer(to: deviceID, play: play)
            }
        }

        public func resumePublisher(
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.resume(deviceID: deviceID)
            }
        }

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

        public func playPublisher(
            uris: [String],
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.play(uris: uris, deviceID: deviceID)
            }
        }

        public func pausePublisher(
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.pause(deviceID: deviceID)
            }
        }

        public func skipToNextPublisher(
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.skipToNext(deviceID: deviceID)
            }
        }

        public func skipToPreviousPublisher(
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.skipToPrevious(deviceID: deviceID)
            }
        }

        public func seekPublisher(
            to positionMs: Int,
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.seek(to: positionMs, deviceID: deviceID)
            }
        }

        public func setRepeatModePublisher(
            _ mode: RepeatMode,
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.setRepeatMode(mode, deviceID: deviceID)
            }
        }

        public func setVolumePublisher(
            _ percent: Int,
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.setVolume(percent, deviceID: deviceID)
            }
        }

        public func setShufflePublisher(
            _ state: Bool,
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.setShuffle(state, deviceID: deviceID)
            }
        }

        public func getQueuePublisher(priority: TaskPriority? = nil) -> AnyPublisher<
            UserQueue, Error
        > {
            publisher(priority: priority) { service in
                try await service.getQueue()
            }
        }

        public func addToQueuePublisher(
            uri: String,
            deviceID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.addToQueue(uri: uri, deviceID: deviceID)
            }
        }

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
    }

#endif

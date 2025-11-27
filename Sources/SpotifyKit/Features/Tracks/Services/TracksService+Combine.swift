#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``TracksService`` async APIs.
    ///
    /// ## Async Counterparts
    /// Use async helpers such as ``TracksService/get(_:market:)`` or ``TracksService/saved(limit:offset:market:)``
    /// when you're writing async/await—the publishers here just wrap them.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension TracksService where Capability: PublicSpotifyCapability {

        /// Get Spotify catalog information for a single track.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the track.
        ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Track` object.
        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Track, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, trackID, market in
                try await service.get(trackID, market: market)
            }
        }

        /// Get Spotify catalog information for several tracks based on their Spotify IDs.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `Track` objects.
        public func severalPublisher(
            ids: Set<String>,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Track], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension TracksService where Capability == UserAuthCapability {

        /// Get a list of the songs saved in the current Spotify user's "Liked Songs" library.
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SavedTrack` items.
        public func savedPublisher(
            limit: Int = 20,
            offset: Int = 0,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SavedTrack>, Error> {
            librarySavedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.saved(limit: limit, offset: offset, market: market)
            }
        }

        /// Fetch all saved tracks from the current user's library.
        ///
        /// - Parameters:
        ///   - market: Optional market filter for track relinking.
        ///   - maxItems: Total number of tracks to fetch. Default: 5,000. Pass `nil` to fetch everything.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array containing every `SavedTrack` up to the requested limit.
        public func allSavedTracksPublisher(
            market: String? = nil,
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedTrack], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedTracks(market: market, maxItems: maxItems)
            }
        }

        /// Save one or more tracks to the current user's library.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when successful.
        public func savePublisher(
            _ ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.save(ids)
            }
        }

        /// Remove one or more tracks from the current user's library.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when successful.
        public func removePublisher(
            _ ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.remove(ids)
            }
        }

        /// Check if one or more tracks are already saved in the current user's library.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of booleans corresponding to the IDs requested.
        public func checkSavedPublisher(
            _ ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Bool], Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.checkSaved(ids)
            }
        }
    }

#endif

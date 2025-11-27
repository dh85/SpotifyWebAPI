#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``EpisodesService`` async APIs.
    ///
    /// ## Async Counterparts
    /// When you would rather use async/await, stick with ``EpisodesService/get(_:market:)`` and
    /// friends—these publishers simply wrap the async implementations.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension EpisodesService where Capability: PublicSpotifyCapability {

        /// Get Spotify catalog information for a single episode.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the episode.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Episode` object.
        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Episode, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, episodeID, market in
                try await service.get(episodeID, market: market)
            }
        }

        /// Get Spotify catalog information for several episodes identified by their Spotify IDs.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `Episode` objects.
        public func severalPublisher(
            ids: Set<String>,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Episode], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension EpisodesService where Capability == UserAuthCapability {

        /// Get a list of the episodes saved in the current Spotify user's library.
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SavedEpisode` items.
        public func savedPublisher(
            limit: Int = 20,
            offset: Int = 0,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SavedEpisode>, Error> {
            librarySavedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.saved(limit: limit, offset: offset, market: market)
            }
        }

        /// Fetch every episode saved in the user's library.
        ///
        /// - Parameters:
        ///   - market: Optional market code for episode relinking.
        ///   - maxItems: Total number of episodes to fetch. Default: 5,000. Pass `nil` for unlimited.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of `SavedEpisode` values aggregated across every page.
        public func allSavedEpisodesPublisher(
            market: String? = nil,
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedEpisode], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedEpisodes(market: market, maxItems: maxItems)
            }
        }

        /// Save one or more episodes to the current Spotify user's library.
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

        /// Remove one or more episodes from the current Spotify user's library.
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

        /// Check if one or more episodes are already saved in the current Spotify user's library.
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

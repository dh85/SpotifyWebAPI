#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``ShowsService`` async APIs.
    ///
    /// ## Async Counterparts
    /// Reach for ``ShowsService/get(_:market:)`` or ``ShowsService/saved(limit:offset:)`` when you
    /// want native async/await—the publishers in this file delegate to those implementations.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension ShowsService where Capability: PublicSpotifyCapability {

        /// Get Spotify catalog information for a single show.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the show.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Show` object.
        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Show, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, showID, market in
                try await service.get(showID, market: market)
            }
        }

        /// Get Spotify catalog information for several shows identified by their Spotify IDs.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `SimplifiedShow` objects.
        public func severalPublisher(
            ids: Set<String>,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SimplifiedShow], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }

        /// Get Spotify catalog information about a show's episodes.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the show.
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SimplifiedEpisode` items.
        public func episodesPublisher(
            for id: String,
            limit: Int = 20,
            offset: Int = 0,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedEpisode>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.episodes(
                    for: id,
                    limit: limit,
                    offset: offset,
                    market: market
                )
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension ShowsService where Capability == UserAuthCapability {

        /// Get a list of shows saved in the current Spotify user's library.
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SavedShow` items.
        public func savedPublisher(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SavedShow>, Error> {
            librarySavedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.saved(limit: limit, offset: offset)
            }
        }

        /// Fetch all shows saved in the current user's library.
        ///
        /// - Parameters:
        ///   - maxItems: Total number of shows to fetch. Default: 5,000. Pass `nil` for unlimited.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of `SavedShow` values aggregated across every page.
        public func allSavedShowsPublisher(
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedShow], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedShows(maxItems: maxItems)
            }
        }

        /// Save one or more shows to the current Spotify user's library.
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

        /// Remove one or more shows from the current Spotify user's library.
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

        /// Check if one or more shows are already saved in the current Spotify user's library.
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

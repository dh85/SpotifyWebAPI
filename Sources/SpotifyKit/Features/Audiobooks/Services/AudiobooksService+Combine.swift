#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``AudiobooksService`` async APIs.
    ///
    /// ## Async Counterparts
    /// Call ``AudiobooksService/get(_:market:)`` or ``AudiobooksService/saved(limit:offset:)`` when
    /// you prefer async/await—these publisher helpers simply wrap those implementations.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension AudiobooksService where Capability: PublicSpotifyCapability {

        /// Get Spotify catalog information for a single audiobook.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the audiobook.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Audiobook` object.
        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Audiobook, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, audiobookID, market in
                try await service.get(audiobookID, market: market)
            }
        }

        /// Get Spotify catalog information for several audiobooks identified by their Spotify IDs.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 50).
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `Audiobook` objects (may contain nil for invalid IDs).
        public func severalPublisher(
            ids: Set<String>,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Audiobook?], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }

        /// Get Spotify catalog information about an audiobook's chapters.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the audiobook.
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SimplifiedChapter` items.
        public func chaptersPublisher(
            for id: String,
            limit: Int = 20,
            offset: Int = 0,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedChapter>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.chapters(
                    for: id,
                    limit: limit,
                    offset: offset,
                    market: market
                )
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension AudiobooksService where Capability == UserAuthCapability {

        /// Get a list of the audiobooks saved in the current Spotify user's 'Your Music' library.
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SavedAudiobook` items.
        public func savedPublisher(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SavedAudiobook>, Error> {
            librarySavedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.saved(limit: limit, offset: offset)
            }
        }

        /// Fetch every saved audiobook in the user's library.
        ///
        /// - Parameters:
        ///   - maxItems: Total number of audiobooks to fetch. Default: 5,000. Pass `nil` for unlimited.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of `SavedAudiobook` values aggregated across every page.
        public func allSavedAudiobooksPublisher(
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedAudiobook], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedAudiobooks(maxItems: maxItems)
            }
        }

        /// Save one or more audiobooks to the current Spotify user's library.
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

        /// Remove one or more audiobooks from the Spotify user's library.
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

        /// Check if one or more audiobooks are already saved in the current Spotify user's library.
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

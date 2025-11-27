#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``AlbumsService`` async methods.
    ///
    /// ## Async Counterparts
    /// When you switch to async/await, call helpers like ``AlbumsService/get(_:market:)`` or
    /// ``AlbumsService/saved(limit:offset:)``—these publishers forward to the same implementations so
    /// validation and instrumentation behave consistently.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension AlbumsService where Capability: PublicSpotifyCapability {

        /// Get Spotify catalog information for a single album.
        /// Corresponds to: `GET /v1/albums/{id}`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the album.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Album` object.
        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Album, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, albumID, market in
                try await service.get(albumID, market: market)
            }
        }

        /// Get Spotify catalog information for multiple albums identified by their Spotify IDs.
        /// Corresponds to: `GET /v1/albums`
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 20).
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `Album` objects.
        public func severalPublisher(
            ids: Set<String>,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Album], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }

        /// Get Spotify catalog information about an album's tracks.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the album.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SimplifiedTrack` items.
        public func tracksPublisher(
            _ id: String,
            market: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedTrack>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.tracks(id, market: market, limit: limit, offset: offset)
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension AlbumsService where Capability == UserAuthCapability {

        /// Get a list of the albums saved in the current Spotify user's 'Your Music' library.
        /// Corresponds to: `GET /v1/me/albums`. Requires the `user-library-read` scope.
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a paginated list of `SavedAlbum` items.
        public func savedPublisher(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SavedAlbum>, Error> {
            librarySavedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.saved(limit: limit, offset: offset)
            }
        }

        /// Fetch all albums saved in the current user's library.
        ///
        /// - Parameters:
        ///   - maxItems: Total number of albums to fetch. Default: 5,000. Pass `nil` for unlimited.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of `SavedAlbum` values aggregated across every page.
        public func allSavedAlbumsPublisher(
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedAlbum], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedAlbums(maxItems: maxItems)
            }
        }

        /// Save one or more albums to the current user's 'Your Music' library.
        /// Corresponds to: `PUT /v1/me/albums`. Requires the `user-library-modify` scope.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 20).
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

        /// Remove one or more albums from the current user's 'Your Music' library.
        /// Corresponds to: `DELETE /v1/me/albums`. Requires the `user-library-modify` scope.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 20).
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

        /// Check if one or more albums is already saved in the current Spotify user's 'Your Music' library.
        /// Corresponds to: `GET /v1/me/albums/contains`. Requires the `user-library-read` scope.
        ///
        /// - Parameters:
        ///   - ids: A list of Spotify IDs (max 20).
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

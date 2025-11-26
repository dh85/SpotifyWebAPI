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

        public func allSavedEpisodesPublisher(
            market: String? = nil,
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedEpisode], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedEpisodes(market: market, maxItems: maxItems)
            }
        }

        public func savePublisher(
            _ ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.save(ids)
            }
        }

        public func removePublisher(
            _ ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.remove(ids)
            }
        }

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

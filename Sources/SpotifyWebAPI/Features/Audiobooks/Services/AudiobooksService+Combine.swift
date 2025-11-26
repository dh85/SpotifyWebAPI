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

        public func allSavedAudiobooksPublisher(
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedAudiobook], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedAudiobooks(maxItems: maxItems)
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

#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension AlbumsService where Capability: PublicSpotifyCapability {

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

        public func allSavedAlbumsPublisher(
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SavedAlbum], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allSavedAlbums(maxItems: maxItems)
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

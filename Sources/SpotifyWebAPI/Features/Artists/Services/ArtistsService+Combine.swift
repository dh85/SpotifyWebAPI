#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension ArtistsService where Capability: PublicSpotifyCapability {

        public func getPublisher(
            _ id: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Artist, Error> {
            catalogItemPublisher(id: id, priority: priority) { service, artistID, _ in
                try await service.get(artistID)
            }
        }

        public func severalPublisher(
            ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Artist], Error> {
            catalogCollectionPublisher(ids: ids, priority: priority) { service, ids, _ in
                try await service.several(ids: ids)
            }
        }

        public func albumsPublisher(
            for id: String,
            includeGroups: Set<AlbumGroup>? = nil,
            market: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedAlbum>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.albums(
                    for: id,
                    includeGroups: includeGroups,
                    market: market,
                    limit: limit,
                    offset: offset
                )
            }
        }

        public func topTracksPublisher(
            for id: String,
            market: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Track], Error> {
            makePublisher(id, market, priority: priority, operation: Self.topTracks)
        }
    }

#endif

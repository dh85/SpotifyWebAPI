#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``ChaptersService`` async APIs.
    ///
    /// ## Async Counterparts
    /// Reach for ``ChaptersService/get(_:market:)`` or ``ChaptersService/several(ids:market:)`` when
    /// you want async/await—the publishers here just wrap those calls.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension ChaptersService where Capability: PublicSpotifyCapability {

        public func getPublisher(
            _ id: String,
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Chapter, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, chapterID, market in
                try await service.get(chapterID, market: market)
            }
        }

        public func severalPublisher(
            ids: [String],
            market: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Chapter], Error> {
            catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
                service, ids, market in
                try await service.several(ids: ids, market: market)
            }
        }
    }

#endif

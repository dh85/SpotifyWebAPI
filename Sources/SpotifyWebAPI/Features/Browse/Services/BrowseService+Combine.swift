#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``BrowseService`` async APIs.
    ///
    /// ## Async Counterparts
    /// When you need async/await, call helpers such as ``BrowseService/newReleases(country:limit:offset:)``.
    /// These publishers wrap those same implementations so validation and paging stay aligned.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension BrowseService where Capability: PublicSpotifyCapability {

        public func newReleasesPublisher(
            country: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedAlbum>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.newReleases(country: country, limit: limit, offset: offset)
            }
        }

        public func categoryPublisher(
            id: String,
            country: String? = nil,
            locale: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<SpotifyCategory, Error> {
            publisher(priority: priority) { service in
                try await service.category(id: id, country: country, locale: locale)
            }
        }

        public func categoriesPublisher(
            country: String? = nil,
            locale: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SpotifyCategory>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.categories(
                    country: country,
                    locale: locale,
                    limit: limit,
                    offset: offset
                )
            }
        }

        public func availableMarketsPublisher(
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[String], Error> {
            publisher(priority: priority) { service in
                try await service.availableMarkets()
            }
        }
    }

#endif

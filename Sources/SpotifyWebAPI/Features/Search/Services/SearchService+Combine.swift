#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension SearchService where Capability: PublicSpotifyCapability {

        public func executePublisher(
            query: String,
            types: Set<SearchType>,
            market: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            includeExternal: ExternalContent? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<SearchResults, Error> {
            publisher(priority: priority) { service in
                try await service.execute(
                    query: query,
                    types: types,
                    market: market,
                    limit: limit,
                    offset: offset,
                    includeExternal: includeExternal
                )
            }
        }
    }

#endif

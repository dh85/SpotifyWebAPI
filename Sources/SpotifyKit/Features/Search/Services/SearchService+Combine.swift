#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``SearchService`` async APIs.
    ///
    /// ## Async Counterparts
    /// Prefer ``SearchService/execute(query:types:market:limit:offset:includeExternal:)`` when you're
    /// writing async/await code—the publisher here simply wraps that call so behavior stays in sync.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension SearchService where Capability: PublicSpotifyCapability {

        /// Search for albums, artists, playlists, tracks, shows, episodes, or audiobooks.
        /// Corresponds to: `GET /v1/search`
        ///
        /// - Parameters:
        ///   - query: Search query keywords and optional field filters and operators.
        ///   - types: A set of item types to search across (album, artist, playlist, track, show, episode, audiobook).
        ///   - market: An ISO 3166-1 alpha-2 country code. If provided, only content available in that market is returned.
        ///   - limit: The maximum number of results to return per type (1-50). Default: 20.
        ///   - offset: The index of the first result to return. Default: 0.
        ///   - includeExternal: If specified, the response will include any relevant audio content that is hosted externally.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a `SearchResults` object containing paginated results for the requested types.
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

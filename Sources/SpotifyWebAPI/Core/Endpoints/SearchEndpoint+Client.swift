import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information about tracks, artists, albums, etc.
    /// that match a keyword string.
    ///
    /// Corresponds to: `GET /v1/search`
    ///
    /// - Parameters:
    ///   - query: The search query.
    ///   - types: A set of item types to search for (e.g., `.track`, `.artist`).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - includeExternal: Optional. If `audio`, includes external audio.
    /// - Returns: A `SearchResults` object containing paged results for
    ///   the requested types.
    public func search(
        query: String,
        types: Set<SearchType>,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        includeExternal: String? = nil
    ) async throws -> SearchResults {

        guard !query.isEmpty, !types.isEmpty else {
            // Spotify requires a query and at least one type.
            // Throwing a client-side error is better than a 400.
            throw SpotifyClientError.unexpectedResponse
        }

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = SearchEndpoint.search(
            query: query,
            types: types,
            market: market,
            limit: clampedLimit,
            offset: offset,
            includeExternal: includeExternal
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(SearchResults.self, url: url)
    }
}

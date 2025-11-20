import Foundation

/// A service providing access to Spotify's global search functionality.
public struct SearchService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access

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
    /// - Returns: A `SearchResults` object containing paginated results for the requested types.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/search)
    public func execute(
        query: String,
        types: Set<SearchType>,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        includeExternal: ExternalContent? = nil
    ) async throws -> SearchResults {
        try validateLimit(limit)

        let queryItems: [URLQueryItem] =
            [
                .init(name: "q", value: query),
                .init(name: "type", value: types.spotifyQueryValue),
            ] + makePaginationQuery(limit: limit, offset: offset)
            + makeMarketQueryItems(from: market)
            + makeIncludeExternalQueryItems(from: includeExternal)

        let request = SpotifyRequest<SearchResults>.get("/search", query: queryItems)
        return try await client.perform(request)
    }
}

// MARK: - Helper Methods

extension SearchService {
    fileprivate func makeIncludeExternalQueryItems(from includeExternal: ExternalContent?) -> [URLQueryItem]
    {
        guard let includeExternal else { return [] }
        return [.init(name: "include_external", value: includeExternal.rawValue)]
    }
}

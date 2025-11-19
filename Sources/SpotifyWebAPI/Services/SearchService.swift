import Foundation

/// A service providing access to Spotify's global search functionality.
public struct SearchService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

extension SearchService where Capability: PublicSpotifyCapability {

    /// Executes a search against the Spotify catalog for tracks, artists, albums, etc., that match a keyword string.
    ///
    /// Corresponds to: `GET /v1/search`.
    ///
    /// - Parameters:
    ///   - query: The search query string (required).
    ///   - types: A set of item types to search across (e.g., ``SearchType/track``, ``SearchType/artist``).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The maximum number of results to return per type (1-50). Default: 20.
    ///   - offset: The index of the first result to return. Default: 0.
    ///   - includeExternal: Optional. If `audio` is specified, includes content like pre-saves.
    /// - Returns: A ``SearchResults`` object containing paginated results for the requested types.
    public func execute(
        query: String,
        types: Set<SearchType>,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        includeExternal: String? = nil
    ) async throws -> SearchResults {

        let clampedLimit = min(max(limit, 1), 50)

        // 1. Build the full query parameter list
        var queryItems: [URLQueryItem] = [
            .init(name: "q", value: query),
            .init(name: "type", value: types.spotifyQueryValue),  // Assumes extension on Set<SearchType> exists
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            queryItems.append(.init(name: "market", value: market))
        }
        if let includeExternal {
            queryItems.append(
                .init(name: "include_external", value: includeExternal)
            )
        }

        // 2. Create the typed request
        let request = SpotifyRequest<SearchResults>.get(
            "/search",
            query: queryItems
        )

        // 3. Dispatch and decode
        return try await client.perform(request)
    }
}

import Foundation

private struct SeveralShowsWrapper: Decodable { let shows: [SimplifiedShow] }

/// A service for fetching and managing Spotify Show (Podcast) resources and their episodes.
public struct ShowsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access
extension ShowsService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single show.
    ///
    /// Corresponds to: `GET /v1/shows/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Show` object.
    public func get(_ id: String, market: String? = nil) async throws -> Show {
        let query: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let request = SpotifyRequest<Show>.get("/shows/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several shows based on their Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/shows`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the shows (max 50).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `SimplifiedShow` objects.
    public func several(ids: Set<String>, market: String? = nil) async throws
        -> [SimplifiedShow]
    {
        let sortedIDs = ids.sorted()
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [.init(name: "ids", value: sortedIDs.joined(separator: ","))]
            + marketQuery

        let request = SpotifyRequest<SeveralShowsWrapper>.get(
            "/shows",
            query: query
        )
        return try await client.perform(request).shows
    }

    /// Get episodes for a specific show.
    ///
    /// Corresponds to: `GET /v1/shows/{id}/episodes`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of `SimplifiedEpisode` items.
    public func episodes(
        for id: String,
        limit: Int = 20,
        offset: Int = 0,
        market: String? = nil
    ) async throws -> Page<SimplifiedEpisode> {
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [
                .init(name: "limit", value: String(limit)),
                .init(name: "offset", value: String(offset)),
            ] + marketQuery

        let request = SpotifyRequest<Page<SimplifiedEpisode>>.get(
            "/shows/\(id)/episodes",
            query: query
        )
        return try await client.perform(request)
    }
}

// MARK: - User Access
extension ShowsService where Capability == UserAuthCapability {

    /// Get the current user's saved shows (podcast subscriptions).
    ///
    /// Corresponds to: `GET /v1/me/shows`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of `SavedShow` items.
    public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<
        SavedShow
    > {
        let query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        let request = SpotifyRequest<Page<SavedShow>>.get(
            "/me/shows",
            query: query
        )
        return try await client.perform(request)
    }

    /// Save one or more shows (podcast subscriptions) for the current user.
    ///
    /// Corresponds to: `PUT /v1/me/shows`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the shows (max 50).
    public func save(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/shows",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Remove saved shows (podcast subscriptions) for the current user.
    ///
    /// Corresponds to: `DELETE /v1/me/shows`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the shows (max 50).
    public func remove(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/shows",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Check if one or more shows are saved by the current user.
    ///
    /// Corresponds to: `GET /v1/me/shows/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the shows (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        let sortedIDs = ids.sorted()

        let query = [
            URLQueryItem(name: "ids", value: sortedIDs.joined(separator: ","))
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/shows/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

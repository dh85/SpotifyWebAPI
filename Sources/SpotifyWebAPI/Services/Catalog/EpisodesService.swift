import Foundation

private struct SeveralEpisodesWrapper: Decodable { let episodes: [Episode] }

/// A service for fetching and managing Spotify Episode (Podcast Episode) resources.
public struct EpisodesService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Public Access
extension EpisodesService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single episode.
    ///
    /// Corresponds to: `GET /v1/episodes/{id}`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the episode.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full ``Episode`` object.
    /// - Throws: ``SpotifyAuthError/httpError(statusCode:body:)`` if the API returns an error.
    public func get(_ id: String, market: String? = nil) async throws -> Episode
    {
        let query: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let request = SpotifyRequest<Episode>.get(
            "/episodes/\(id)",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several episodes.
    ///
    /// Corresponds to: `GET /v1/episodes`.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the episodes (max 50).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full ``Episode`` objects.
    public func several(ids: Set<String>, market: String? = nil) async throws
        -> [Episode]
    {
        let sortedIDs = ids.sorted()
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [.init(name: "ids", value: sortedIDs.joined(separator: ","))]
            + marketQuery

        let request = SpotifyRequest<SeveralEpisodesWrapper>.get(
            "/episodes",
            query: query
        )
        return try await client.perform(request).episodes
    }
}

// MARK: - User Access
extension EpisodesService where Capability == UserAuthCapability {

    /// Get a list of the episodes saved in the current user's library.
    ///
    /// Corresponds to: `GET /v1/me/episodes`.
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of ``SavedEpisode`` items.
    public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil)
        async throws -> Page<SavedEpisode>
    {
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [
                .init(name: "limit", value: String(limit)),
                .init(name: "offset", value: String(offset)),
            ] + marketQuery

        let request = SpotifyRequest<Page<SavedEpisode>>.get(
            "/me/episodes",
            query: query
        )
        return try await client.perform(request)
    }

    /// Save one or more episodes to the current user's library.
    ///
    /// Corresponds to: `PUT /v1/me/episodes`.
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the episodes (max 50).
    public func save(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/episodes",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Remove saved episodes for the current user.
    ///
    /// Corresponds to: `DELETE /v1/me/episodes`.
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the episodes (max 50).
    public func remove(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/episodes",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Check if episodes are saved by the current user.
    ///
    /// Corresponds to: `GET /v1/me/episodes/contains`.
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the episodes (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        let sortedIDs = ids.sorted()

        let query = [
            URLQueryItem(name: "ids", value: sortedIDs.joined(separator: ","))
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/episodes/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

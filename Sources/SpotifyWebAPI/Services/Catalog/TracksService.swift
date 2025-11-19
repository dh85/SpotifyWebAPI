import Foundation

private struct SeveralTracksWrapper: Decodable { let tracks: [Track?] }

/// A service for fetching and managing Spotify Track resources.
public struct TracksService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Capability
extension TracksService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single track.
    ///
    /// Corresponds to: `GET /v1/tracks/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the track.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Track` object.
    public func get(_ id: String, market: String? = nil) async throws -> Track {
        let query: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let request = SpotifyRequest<Track>.get("/tracks/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several tracks based on their Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/tracks`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the tracks (max 50).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full `Track` objects (invalid IDs are filtered out).
    public func several(ids: Set<String>, market: String? = nil) async throws
        -> [Track]
    {
        let sortedIDs = ids.sorted()
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [.init(name: "ids", value: sortedIDs.joined(separator: ","))]
            + marketQuery

        let request = SpotifyRequest<SeveralTracksWrapper>.get(
            "/tracks",
            query: query
        )
        // Filter out null tracks returned by the API for invalid IDs
        return try await client.perform(request).tracks.compactMap { $0 }
    }
}

// MARK: - User Access
extension TracksService where Capability == UserAuthCapability {

    /// Get a list of the songs saved in the current Spotify user's "Liked Songs" library.
    ///
    /// Corresponds to: `GET /v1/me/tracks`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of `SavedTrack` items.
    public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil)
        async throws -> Page<SavedTrack>
    {
        let marketQuery: [URLQueryItem] =
            market.map {
                [.init(name: "market", value: $0)]
            } ?? []

        let query: [URLQueryItem] =
            [
                .init(name: "limit", value: String(limit)),
                .init(name: "offset", value: String(offset)),
            ] + marketQuery

        let request = SpotifyRequest<Page<SavedTrack>>.get(
            "/me/tracks",
            query: query
        )
        return try await client.perform(request)
    }

    /// Save one or more tracks to the current user's library.
    ///
    /// Corresponds to: `PUT /v1/me/tracks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the tracks (max 50).
    public func save(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/tracks",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Remove one or more tracks from the current user's library.
    ///
    /// Corresponds to: `DELETE /v1/me/tracks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the tracks (max 50).
    public func remove(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/tracks",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Check if one or more tracks are already saved in the current user's library.
    ///
    /// Corresponds to: `GET /v1/me/tracks/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the tracks (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        let sortedIDs = ids.sorted()

        let query = [
            URLQueryItem(name: "ids", value: sortedIDs.joined(separator: ","))
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/tracks/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

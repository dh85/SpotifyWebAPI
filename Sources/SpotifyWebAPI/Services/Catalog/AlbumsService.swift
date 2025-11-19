import Foundation

private struct SeveralAlbumsWrapper: Decodable {
    let albums: [Album]
}

private let MAXIMUM_ALBUM_ID_BATCH_SIZE = 20

/// A service for fetching and managing Spotify Album resources.
public struct AlbumsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access

extension AlbumsService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single album.
    ///
    /// Corresponds to: `GET /v1/albums/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Album` object.
    public func get(_ id: String, market: String? = nil) async throws -> Album {
        let request = SpotifyRequest<Album>.get(
            "/albums/\(id)",
            query: makeMarketQueryItems(from: market)
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several albums based on their Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/albums`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the albums (max 20).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full `Album` objects.
    public func several(
        ids: Set<String>,
        market: String? = nil
    ) async throws -> [Album] {
        try validateMaxIdCount(MAXIMUM_ALBUM_ID_BATCH_SIZE, for: ids)

        let query: [URLQueryItem] =
            [makeIDsQueryItem(from: ids)] + makeMarketQueryItems(from: market)

        let request = SpotifyRequest<SeveralAlbumsWrapper>.get(
            "/albums",
            query: query
        )
        let response = try await client.perform(request)
        return response.albums
    }

    /// Get Spotify catalog information about an album's tracks.
    ///
    /// Corresponds to: `GET /v1/albums/{id}/tracks`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SimplifiedTrack` items.
    public func tracks(
        _ id: String,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedTrack> {
        try validateLimit(limit)

        var query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        query += makeMarketQueryItems(from: market)

        let request = SpotifyRequest<Page<SimplifiedTrack>>.get(
            "/albums/\(id)/tracks",
            query: query
        )
        return try await client.perform(request)
    }
}

// MARK: - User Access

extension AlbumsService where Capability == UserAuthCapability {

    /// Get a list of the albums saved in the current Spotify user's library.
    ///
    /// Corresponds to: `GET /v1/me/albums`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SavedAlbum` items.
    public func saved(
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SavedAlbum> {
        try validateLimit(limit)

        let query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        let request = SpotifyRequest<Page<SavedAlbum>>.get(
            "/me/albums",
            query: query
        )
        return try await client.perform(request)
    }

    /// Save one or more albums to the current user's library.
    ///
    /// Corresponds to: `PUT /v1/me/albums`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the albums (max 20).
    public func save(_ ids: Set<String>) async throws {
        try validateMaxIdCount(MAXIMUM_ALBUM_ID_BATCH_SIZE, for: ids)

        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/albums",
            body: IDsBody(ids: ids)
        )

        // Perform the request. The result is discarded because the method returns Void.
        try await client.perform(request)
    }

    /// Remove one or more albums from the current user's library.
    ///
    /// Corresponds to: `DELETE /v1/me/albums`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the albums (max 20).
    public func remove(_ ids: Set<String>) async throws {
        try validateMaxIdCount(MAXIMUM_ALBUM_ID_BATCH_SIZE, for: ids)

        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/albums",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Check if one or more albums are already saved in the current user's library.
    ///
    /// Corresponds to: `GET /v1/me/albums/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the albums (max 20).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        try validateMaxIdCount(MAXIMUM_ALBUM_ID_BATCH_SIZE, for: ids)

        let query: [URLQueryItem] = [makeIDsQueryItem(from: ids)]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/albums/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

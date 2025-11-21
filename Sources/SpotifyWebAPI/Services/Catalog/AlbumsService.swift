import Foundation

private typealias SeveralAlbumsWrapper = ArrayWrapper<Album>

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
    /// Corresponds to: `GET /v1/albums/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Album` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
    public func get(_ id: String, market: String? = nil) async throws -> Album {
        let request = SpotifyRequest<Album>.get(
            "/albums/\(id)",
            query: makeMarketQueryItems(from: market)
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for multiple albums identified by their Spotify IDs.
    /// Corresponds to: `GET /v1/albums`
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 20).
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `Album` objects.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-albums)
    public func several(ids: Set<String>, market: String? = nil) async throws -> [Album] {
        try validateAlbumIDs(ids)

        let query = [makeIDsQueryItem(from: ids)] + makeMarketQueryItems(from: market)
        let request = SpotifyRequest<SeveralAlbumsWrapper>.get("/albums", query: query)
        return try await client.perform(request).items
    }

    /// Get Spotify catalog information about an album's tracks.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SimplifiedTrack` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-albums-tracks)
    public func tracks(
        _ id: String,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedTrack> {
        try validateLimit(limit)

        let query = makePagedMarketQuery(limit: limit, offset: offset, market: market)
        let request = SpotifyRequest<Page<SimplifiedTrack>>.get(
            "/albums/\(id)/tracks", query: query)
        return try await client.perform(request)
    }
}

// MARK: - User Access

extension AlbumsService where Capability == UserAuthCapability {

    /// Get a list of the albums saved in the current Spotify user's 'Your Music' library.
    /// Corresponds to: `GET /v1/me/albums`. Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SavedAlbum` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-albums)
    public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAlbum> {
        try validateLimit(limit)
        let query = makePaginationQuery(limit: limit, offset: offset)
        let request = SpotifyRequest<Page<SavedAlbum>>.get("/me/albums", query: query)
        return try await client.perform(request)
    }

    /// Save one or more albums to the current user's 'Your Music' library.
    /// Corresponds to: `PUT /v1/me/albums`. Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 20).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-albums-user)
    public func save(_ ids: Set<String>) async throws {
        try validateAlbumIDs(ids)
        try await performLibraryOperation(.put, endpoint: "/me/albums", ids: ids, client: client)
    }

    /// Remove one or more albums from the current user's 'Your Music' library.
    /// Corresponds to: `DELETE /v1/me/albums`. Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 20).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-albums-user)
    public func remove(_ ids: Set<String>) async throws {
        try validateAlbumIDs(ids)
        try await performLibraryOperation(.delete, endpoint: "/me/albums", ids: ids, client: client)
    }

    /// Check if one or more albums is already saved in the current Spotify user's 'Your Music' library.
    /// Corresponds to: `GET /v1/me/albums/contains`. Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 20).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-albums)
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        try validateAlbumIDs(ids)
        let query = [makeIDsQueryItem(from: ids)]
        let request = SpotifyRequest<[Bool]>.get("/me/albums/contains", query: query)
        return try await client.perform(request)
    }
}

// MARK: - Helper Methods

extension AlbumsService {
    fileprivate func validateAlbumIDs(_ ids: Set<String>) throws {
        try validateMaxIdCount(MAXIMUM_ALBUM_ID_BATCH_SIZE, for: ids)
    }
}

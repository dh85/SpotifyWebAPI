import Foundation

private typealias SeveralShowsWrapper = ArrayWrapper<SimplifiedShow>

private let MAXIMUM_SHOW_ID_BATCH_SIZE = 50

/// A service for fetching and managing Spotify Show (Podcast) resources and their episodes.
public struct ShowsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension ShowsService {
    private func validateShowIDs(_ ids: Set<String>) throws {
        try validateMaxIdCount(MAXIMUM_SHOW_ID_BATCH_SIZE, for: ids)
    }
}

// MARK: - Public Access
extension ShowsService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single show.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Show` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-show)
    public func get(_ id: String, market: String? = nil) async throws -> Show {
        let query = makeMarketQueryItems(from: market)
        let request = SpotifyRequest<Show>.get("/shows/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several shows identified by their Spotify IDs.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `SimplifiedShow` objects.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-shows)
    public func several(ids: Set<String>, market: String? = nil) async throws -> [SimplifiedShow] {
        try validateShowIDs(ids)
        let query = [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
            + makeMarketQueryItems(from: market)
        let request = SpotifyRequest<SeveralShowsWrapper>.get("/shows", query: query)
        return try await client.perform(request).items
    }

    /// Get Spotify catalog information about a show's episodes.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of `SimplifiedEpisode` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-shows-episodes)
    public func episodes(
        for id: String,
        limit: Int = 20,
        offset: Int = 0,
        market: String? = nil
    ) async throws -> Page<SimplifiedEpisode> {
        try validateLimit(limit)
        let query = makePagedMarketQuery(limit: limit, offset: offset, market: market)
        let request = SpotifyRequest<Page<SimplifiedEpisode>>.get("/shows/\(id)/episodes", query: query)
        return try await client.perform(request)
    }
}

// MARK: - User Access
extension ShowsService where Capability == UserAuthCapability {

    /// Get a list of shows saved in the current Spotify user's library.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SavedShow` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-shows)
    public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedShow> {
        try validateLimit(limit)
        let query = makePaginationQuery(limit: limit, offset: offset)
        let request = SpotifyRequest<Page<SavedShow>>.get("/me/shows", query: query)
        return try await client.perform(request)
    }

    /// Save one or more shows to the current Spotify user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-shows-user)
    public func save(_ ids: Set<String>) async throws {
        try validateShowIDs(ids)
        try await performLibraryOperation(.put, endpoint: "/me/shows", ids: ids, client: client)
    }

    /// Remove one or more shows from the current Spotify user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-shows-user)
    public func remove(_ ids: Set<String>) async throws {
        try validateShowIDs(ids)
        try await performLibraryOperation(.delete, endpoint: "/me/shows", ids: ids, client: client)
    }

    /// Check if one or more shows are already saved in the current Spotify user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-shows)
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        try validateShowIDs(ids)
        let query = [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
        let request = SpotifyRequest<[Bool]>.get("/me/shows/contains", query: query)
        return try await client.perform(request)
    }
}

import Foundation

private typealias SeveralTracksWrapper = ArrayWrapper<Track?>

/// A service for fetching and managing Spotify Track resources.
///
/// ## Overview
///
/// TracksService provides access to:
/// - Track catalog information
/// - User's saved tracks ("Liked Songs")
/// - Batch operations for saving/removing tracks
///
/// ## Examples
///
/// ### Get Track Details
/// ```swift
/// let track = try await client.tracks.get("11dFghVXANMlKmJXsNCbNl")
/// print("\(track.name) by \(track.artistNames)")
/// print("Duration: \(track.durationFormatted)")
/// print("Album: \(track.album.name)")
/// ```
///
/// ### Get Multiple Tracks
/// ```swift
/// let trackIDs: Set<String> = ["track1", "track2", "track3"]
/// let tracks = try await client.tracks.several(ids: trackIDs)
/// for track in tracks {
///     print("\(track.name) - \(track.durationFormatted)")
/// }
/// ```
///
/// ### Save Tracks to Liked Songs
/// ```swift
/// // Save single track
/// try await client.tracks.save(["11dFghVXANMlKmJXsNCbNl"])
///
/// // Save many tracks (automatically chunked into batches of 50)
/// let manyTracks = ["track1", "track2", ...] // 200 tracks
/// try await client.tracks.saveAll(manyTracks)
/// ```
///
/// ### Get Saved Tracks
/// ```swift
/// let savedTracks = try await client.tracks.saved(limit: 50)
/// for item in savedTracks.items {
///     let track = item.track
///     print("\(track.name) - saved on \(item.addedAt)")
/// }
/// ```
///
/// - SeeAlso: ``LibraryServiceExtensions`` for batch operations
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
public struct TracksService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }

    private func validateTrackIDs(_ ids: Set<String>) throws {
        try validateMaxIdCount(50, for: ids)
    }
}

// MARK: - Public Capability
extension TracksService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single track.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the track.
    ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
    /// - Returns: A full `Track` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
    public func get(_ id: String, market: String? = nil) async throws -> Track {
        let query = makeMarketQueryItems(from: market)
        let request = SpotifyRequest<Track>.get("/tracks/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several tracks based on their Spotify IDs.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
    /// - Returns: A list of `Track` objects.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-several-tracks)
    public func several(ids: Set<String>, market: String? = nil) async throws -> [Track] {
        try validateTrackIDs(ids)
        let query =
            [URLQueryItem(name: "ids", value: ids.joined(separator: ","))]
            + makeMarketQueryItems(from: market)
        let request = SpotifyRequest<SeveralTracksWrapper>.get("/tracks", query: query)
        return try await client.perform(request).items.compactMap { $0 }
    }
}

// MARK: - User Access
extension TracksService where Capability == UserAuthCapability {

    /// Get a list of the songs saved in the current Spotify user's "Liked Songs" library.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
    /// - Returns: A paginated list of `SavedTrack` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks)
    public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil) async throws -> Page<
        SavedTrack
    > {
        let query =
            try buildPaginationQuery(limit: limit, offset: offset)
            + makeMarketQueryItems(from: market)
        let request = SpotifyRequest<Page<SavedTrack>>.get("/me/tracks", query: query)
        return try await client.perform(request)
    }

    /// Fetch all saved tracks from the current user's library.
    ///
    /// - Parameters:
    ///   - market: Optional market filter for track relinking.
    ///   - maxItems: Total number of tracks to fetch. Default: 5,000. Pass `nil` to fetch everything.
    /// - Returns: Array containing every `SavedTrack` up to the requested limit.
    /// - Throws: `SpotifyError` if the request fails.
    public func allSavedTracks(
        market: String? = nil,
        maxItems: Int? = 5000
    ) async throws -> [SavedTrack] {
        try await savedTracksProvider(market: market, defaultMaxItems: 5000).all(maxItems: maxItems)
    }

    /// Stream saved tracks one-by-one as they are fetched.
    ///
    /// - Parameters:
    ///   - market: Optional market filter for track relinking.
    ///   - maxItems: Optional cap on streamed items. Default: `nil` (no limit).
    /// - Returns: An async sequence emitting `SavedTrack` values lazily.
    public func streamSavedTracks(
        market: String? = nil,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<SavedTrack, Error> {
        savedTracksProvider(market: market, defaultMaxItems: nil).stream(maxItems: maxItems)
    }

    private func savedTracksProvider(
        market: String?,
        defaultMaxItems: Int?
    ) -> AllItemsProvider<Capability, SavedTrack> {
        client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) { limit, offset in
            try await self.saved(limit: limit, offset: offset, market: market)
        }
    }

    /// Save one or more tracks to the current user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-tracks-user)
    public func save(_ ids: Set<String>) async throws {
        try validateTrackIDs(ids)
        try await performLibraryOperation(.put, endpoint: "/me/tracks", ids: ids, client: client)
    }

    /// Remove one or more tracks from the current user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-tracks-user)
    public func remove(_ ids: Set<String>) async throws {
        try validateTrackIDs(ids)
        try await performLibraryOperation(.delete, endpoint: "/me/tracks", ids: ids, client: client)
    }

    /// Check if one or more tracks are already saved in the current user's library.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-tracks)
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        try validateTrackIDs(ids)
        let query = [URLQueryItem(name: "ids", value: ids.joined(separator: ","))]
        let request = SpotifyRequest<[Bool]>.get("/me/tracks/contains", query: query)
        return try await client.perform(request)
    }
}

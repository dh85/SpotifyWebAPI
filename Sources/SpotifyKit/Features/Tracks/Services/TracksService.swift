import Foundation

private typealias SeveralTracksWrapper = ArrayWrapper<Track>

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
/// - Note: Batch save/remove helpers for user libraries live in `LibraryServiceExtensions.swift`.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
///
/// ## Combine Counterparts
///
/// Combine publishers—like ``TracksService/getPublisher(_:market:priority:)`` and
/// ``TracksService/savedPublisher(limit:offset:market:priority:)``—live in
/// `TracksService+Combine.swift`. Import Combine to switch paradigms without hunting for another
/// type.
public struct TracksService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
}

extension TracksService: ServiceIDValidating {
  static var maxBatchSize: Int { SpotifyAPILimits.Tracks.catalogBatchSize }

  private func validateTrackIDs(_ ids: Set<String>) throws {
    try validateIDs(ids)
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
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
  public func get(_ id: String, market: String? = nil) async throws -> Track {
    return
      try await client
      .get("/tracks/\(id)")
      .market(market)
      .decode(Track.self)
  }

  /// Get Spotify catalog information for several tracks based on their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An [ISO 3166-1 alpha-2 country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
  /// - Returns: A list of `Track` objects.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-several-tracks)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Track] {
    try validateTrackIDs(ids)

    let wrapper =
      try await client
      .get("/tracks")
      .query("ids", ids.joined(separator: ","))
      .market(market)
      .decode(SeveralTracksWrapper.self)
    return wrapper.items
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
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-tracks)
  public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil) async throws -> Page<
    SavedTrack
  > {
    try validateLimit(limit)
    return
      try await client
      .get("/me/tracks")
      .paginate(limit: limit, offset: offset)
      .market(market)
      .decode(Page<SavedTrack>.self)
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
    client.streamItems(pageSize: 50, maxItems: maxItems) { limit, offset in
      try await self.saved(limit: limit, offset: offset, market: market)
    }
  }

  /// Streams saved tracks page-by-page, allowing callers to batch work per response.
  ///
  /// - Parameters:
  ///   - market: Optional market filter for track relinking.
  ///   - maxPages: Optional limit on the number of pages to emit.
  public func streamSavedTrackPages(
    market: String? = nil,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SavedTrack>, Error> {
    client.streamPages(pageSize: 50, maxPages: maxPages) { limit, offset in
      try await self.saved(limit: limit, offset: offset, market: market)
    }
  }

  /// Save one or more tracks to the current user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-tracks-user)
  public func save(_ ids: Set<String>) async throws {
    try validateTrackIDs(ids)
    try await performLibraryOperation(.put, endpoint: "/me/tracks", ids: ids, client: client)
  }

  /// Remove one or more tracks from the current user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
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
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-tracks)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateTrackIDs(ids)
    return
      try await client
      .get("/me/tracks/contains")
      .query("ids", ids.joined(separator: ","))
      .decode([Bool].self)
  }
}

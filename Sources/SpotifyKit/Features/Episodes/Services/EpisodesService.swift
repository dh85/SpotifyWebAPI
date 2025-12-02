import Foundation

private typealias SeveralEpisodesWrapper = ArrayWrapper<Episode>

/// A service for fetching and managing Spotify Episode (Podcast Episode) resources.
///
/// ## Combine Counterparts
///
/// Publisher helpers such as ``EpisodesService/getPublisher(_:market:priority:)`` and
/// ``EpisodesService/savedPublisher(limit:offset:market:priority:)`` are defined in
/// `EpisodesService+Combine.swift`. Import Combine to expose them—they reuse these async methods so
/// both concurrency models behave the same.
public struct EpisodesService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
  init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension EpisodesService: ServiceIDValidating {
  static var maxBatchSize: Int { SpotifyAPILimits.Episodes.batchSize }

  private func validateEpisodeIDs(_ ids: Set<String>) throws {
    try validateIDs(ids)
  }
}

// MARK: - Public Access
extension EpisodesService where Capability: PublicSpotifyCapability {

  /// Get Spotify catalog information for a single episode.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the episode.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A full `Episode` object.
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-episode)
  public func get(_ id: String, market: String? = nil) async throws -> Episode {
    return
      try await client
      .get("/episodes/\(id)")
      .market(market)
      .decode(Episode.self)
  }

  /// Get Spotify catalog information for several episodes identified by their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `Episode` objects.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-episodes)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Episode] {
    try validateEpisodeIDs(ids)
    let wrapper =
      try await client
      .get("/episodes")
      .query("ids", ids.sorted().joined(separator: ","))
      .market(market)
      .decode(SeveralEpisodesWrapper.self)
    return wrapper.items
  }
}

// MARK: - User Access
extension EpisodesService where Capability == UserAuthCapability {

  /// Get a list of the episodes saved in the current Spotify user's library.
  ///
  /// - Parameters:
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A paginated list of `SavedEpisode` items.
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-episodes)
  public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil) async throws -> Page<
    SavedEpisode
  > {
    try validateLimit(limit)
    return
      try await client
      .get("/me/episodes")
      .paginate(limit: limit, offset: offset)
      .market(market)
      .decode(Page<SavedEpisode>.self)
  }

  /// Fetch every episode saved in the user's library.
  ///
  /// - Parameters:
  ///   - market: Optional market code for episode relinking.
  ///   - maxItems: Total number of episodes to fetch. Default: 5,000. Pass `nil` for unlimited.
  public func allSavedEpisodes(
    market: String? = nil,
    maxItems: Int? = 5000
  ) async throws -> [SavedEpisode] {
    try await savedEpisodesProvider(market: market, defaultMaxItems: 5000)
      .all(maxItems: maxItems)
  }

  /// Streams saved episodes as they are fetched.
  ///
  /// - Parameters:
  ///   - market: Optional market code for episode relinking.
  ///   - maxItems: Optional cap on emitted items.
  public func streamSavedEpisodes(
    market: String? = nil,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SavedEpisode, Error> {
    savedEpisodesProvider(market: market, defaultMaxItems: nil).stream(maxItems: maxItems)
  }

  /// Streams full pages of saved episodes, ideal for batching progress updates.
  ///
  /// - Parameters:
  ///   - market: Optional market code for episode relinking.
  ///   - maxPages: Optional limit on emitted pages.
  public func streamSavedEpisodePages(
    market: String? = nil,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SavedEpisode>, Error> {
    savedEpisodesProvider(market: market, defaultMaxItems: nil).streamPages(maxPages: maxPages)
  }

  private func savedEpisodesProvider(
    market: String?,
    defaultMaxItems: Int?
  ) -> AllItemsProvider<Capability, SavedEpisode> {
    client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) {
      limit, offset in
      try await self.saved(limit: limit, offset: offset, market: market)
    }
  }

  /// Save one or more episodes to the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-episodes-user)
  public func save(_ ids: Set<String>) async throws {
    try validateEpisodeIDs(ids)
    try await performLibraryOperation(.put, endpoint: "/me/episodes", ids: ids, client: client)
  }

  /// Remove one or more episodes from the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-episodes-user)
  public func remove(_ ids: Set<String>) async throws {
    try validateEpisodeIDs(ids)
    try await performLibraryOperation(
      .delete, endpoint: "/me/episodes", ids: ids, client: client)
  }

  /// Check if one or more episodes are already saved in the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Returns: An array of booleans corresponding to the IDs requested.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-episodes)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateEpisodeIDs(ids)
    return
      try await client
      .get("/me/episodes/contains")
      .query("ids", ids.sorted().joined(separator: ","))
      .decode([Bool].self)
  }
}

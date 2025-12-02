import Foundation

private typealias SeveralShowsWrapper = ArrayWrapper<SimplifiedShow>

/// A service for fetching and managing Spotify Show (Podcast) resources and their episodes.
///
/// ## Combine Counterparts
///
/// `ShowsService+Combine.swift` exposes publisher helpers such as
/// ``ShowsService/getPublisher(_:market:priority:)`` and
/// ``ShowsService/savedPublisher(limit:offset:priority:)`` so Combine-heavy clients can call the
/// same operations without duplicating logic.
public struct ShowsService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
  init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension ShowsService: ServiceIDValidating {
  static var maxBatchSize: Int { SpotifyAPILimits.Shows.batchSize }

  private func validateShowIDs(_ ids: Set<String>) throws {
    try validateIDs(ids)
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
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-show)
  public func get(_ id: String, market: String? = nil) async throws -> Show {
    return
      try await client
      .get("/shows/\(id)")
      .market(market)
      .decode(Show.self)
  }

  /// Get Spotify catalog information for several shows identified by their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `SimplifiedShow` objects.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-shows)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [SimplifiedShow] {
    try validateShowIDs(ids)
    let wrapper =
      try await client
      .get("/shows")
      .query("ids", ids.sorted().joined(separator: ","))
      .market(market)
      .decode(SeveralShowsWrapper.self)
    return wrapper.items
  }

  /// Get Spotify catalog information about a show's episodes.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the show.
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A paginated list of `SimplifiedEpisode` items.
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-shows-episodes)
  public func episodes(
    for id: String,
    limit: Int = 20,
    offset: Int = 0,
    market: String? = nil
  ) async throws -> Page<SimplifiedEpisode> {
    try validateLimit(limit)
    return
      try await client
      .get("/shows/\(id)/episodes")
      .paginate(limit: limit, offset: offset)
      .market(market)
      .decode(Page<SimplifiedEpisode>.self)
  }

  /// Streams a show's episodes one page at a time for chunked updates.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the show.
  ///   - market: Optional market filter for relinking episodes.
  ///   - pageSize: Number of episodes to request per page (clamped to 1...50). Default: 50.
  ///   - maxPages: Optional cap on total pages emitted.
  public func streamEpisodePages(
    for id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SimplifiedEpisode>, Error> {
    client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
      try await self.episodes(
        for: id,
        limit: limit,
        offset: offset,
        market: market
      )
    }
  }

  /// Streams a show's episodes individually for sequential processing.
  public func streamEpisodes(
    for id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SimplifiedEpisode, Error> {
    client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
      try await self.episodes(
        for: id,
        limit: limit,
        offset: offset,
        market: market
      )
    }
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
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-shows)
  public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedShow> {
    try validateLimit(limit)
    return
      try await client
      .get("/me/shows")
      .paginate(limit: limit, offset: offset)
      .decode(Page<SavedShow>.self)
  }

  /// Fetch all shows saved in the current user's library.
  ///
  /// - Parameter maxItems: Total number of shows to fetch. Default: 5,000. Pass `nil` for unlimited.
  public func allSavedShows(maxItems: Int? = 5000) async throws -> [SavedShow] {
    try await savedShowsProvider(defaultMaxItems: 5000).all(maxItems: maxItems)
  }

  /// Streams saved shows as they are fetched.
  ///
  /// - Parameter maxItems: Optional limit on emitted shows. Default: `nil`.
  public func streamSavedShows(maxItems: Int? = nil) -> AsyncThrowingStream<SavedShow, Error> {
    savedShowsProvider(defaultMaxItems: nil).stream(maxItems: maxItems)
  }

  /// Streams entire pages of saved shows for batched processing.
  ///
  /// - Parameter maxPages: Optional limit on the number of pages to emit.
  public func streamSavedShowPages(maxPages: Int? = nil)
    -> AsyncThrowingStream<Page<SavedShow>, Error>
  {
    savedShowsProvider(defaultMaxItems: nil).streamPages(maxPages: maxPages)
  }

  private func savedShowsProvider(
    defaultMaxItems: Int?
  ) -> AllItemsProvider<Capability, SavedShow> {
    client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) {
      limit, offset in
      try await self.saved(limit: limit, offset: offset)
    }
  }

  /// Save one or more shows to the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-shows-user)
  public func save(_ ids: Set<String>) async throws {
    try validateShowIDs(ids)
    try await performLibraryOperation(.put, endpoint: "/me/shows", ids: ids, client: client)
  }

  /// Remove one or more shows from the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
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
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-shows)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateShowIDs(ids)
    return
      try await client
      .get("/me/shows/contains")
      .query("ids", ids.sorted().joined(separator: ","))
      .decode([Bool].self)
  }
}

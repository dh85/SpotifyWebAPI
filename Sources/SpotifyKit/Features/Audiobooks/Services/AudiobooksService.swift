import Foundation

private typealias SeveralAudiobooksWrapper = ArrayWrapper<Audiobook?>

/// A service for fetching and managing Spotify Audiobook resources and their chapters.
///
/// ## Combine Counterparts
///
/// Publisher variants—like ``AudiobooksService/getPublisher(_:market:priority:)`` and
/// ``AudiobooksService/savedPublisher(limit:offset:priority:)``—live in `AudiobooksService+Combine.swift`.
/// Import Combine to expose those helpers; they reuse the async implementations defined here.
public struct AudiobooksService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
}

// MARK: - Helpers
extension AudiobooksService: ServiceIDValidating {
  static var maxBatchSize: Int { SpotifyAPILimits.Audiobooks.batchSize }

  private func validateAudiobookIDs(_ ids: Set<String>) throws {
    try validateIDs(ids)
  }
}

// MARK: - Public Access
extension AudiobooksService where Capability: PublicSpotifyCapability {

  /// Get Spotify catalog information for a single audiobook.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the audiobook.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A full `Audiobook` object.
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
  public func get(_ id: String, market: String? = nil) async throws -> Audiobook {
    return
      try await client
      .get("/audiobooks/\(id)")
      .market(market)
      .decode(Audiobook.self)
  }

  /// Get Spotify catalog information for several audiobooks identified by their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `Audiobook` objects (may contain nil for invalid IDs).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-audiobooks)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Audiobook?] {
    try validateAudiobookIDs(ids)
    let wrapper =
      try await client
      .get("/audiobooks")
      .query("ids", ids.sorted().joined(separator: ","))
      .market(market)
      .decode(SeveralAudiobooksWrapper.self)
    return wrapper.items
  }

  /// Get Spotify catalog information about an audiobook's chapters.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the audiobook.
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A paginated list of `SimplifiedChapter` items.
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-audiobook-chapters)
  public func chapters(
    for id: String,
    limit: Int = 20,
    offset: Int = 0,
    market: String? = nil
  ) async throws -> Page<SimplifiedChapter> {
    try validateLimit(limit)
    return
      try await client
      .get("/audiobooks/\(id)/chapters")
      .paginate(limit: limit, offset: offset)
      .market(market)
      .decode(Page<SimplifiedChapter>.self)
  }

  /// Streams an audiobook's chapters page-by-page for responsive UIs.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the audiobook.
  ///   - market: Optional market filter.
  ///   - pageSize: Desired number of chapters per request (clamped to 1...50). Default: 50.
  ///   - maxPages: Optional limit on emitted pages.
  public func streamChapterPages(
    for id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SimplifiedChapter>, Error> {
    client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
      try await self.chapters(
        for: id,
        limit: limit,
        offset: offset,
        market: market
      )
    }
  }

  /// Streams an audiobook's chapters individually.
  public func streamChapters(
    for id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SimplifiedChapter, Error> {
    client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
      try await self.chapters(
        for: id,
        limit: limit,
        offset: offset,
        market: market
      )
    }
  }
}

// MARK: - User Access
extension AudiobooksService where Capability == UserAuthCapability {

  /// Get a list of the audiobooks saved in the current Spotify user's 'Your Music' library.
  ///
  /// - Parameters:
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  /// - Returns: A paginated list of `SavedAudiobook` items.
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-audiobooks)
  public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAudiobook> {
    try validateLimit(limit)
    return
      try await client
      .get("/me/audiobooks")
      .paginate(limit: limit, offset: offset)
      .decode(Page<SavedAudiobook>.self)
  }

  /// Streams saved audiobooks lazily.
  ///
  /// - Parameter maxItems: Optional limit on emitted audiobooks.
  public func streamSavedAudiobooks(maxItems: Int? = nil)
    -> AsyncThrowingStream<SavedAudiobook, Error>
  {
    client.streamItems(pageSize: 50, maxItems: maxItems) { limit, offset in
      try await self.saved(limit: limit, offset: offset)
    }
  }

  /// Streams full pages of saved audiobooks for batched processing.
  ///
  /// - Parameter maxPages: Optional limit on the number of pages to emit.
  /// - Returns: Async sequence yielding `Page` batches directly from the API.
  public func streamSavedAudiobookPages(maxPages: Int? = nil)
    -> AsyncThrowingStream<Page<SavedAudiobook>, Error>
  {
    client.streamPages(pageSize: 50, maxPages: maxPages) { limit, offset in
      try await self.saved(limit: limit, offset: offset)
    }
  }

  /// Save one or more audiobooks to the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-audiobooks-user)
  public func save(_ ids: Set<String>) async throws {
    try validateAudiobookIDs(ids)
    try await performLibraryOperation(
      .put, endpoint: "/me/audiobooks", ids: ids, client: client)
  }

  /// Remove one or more audiobooks from the Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-audiobooks-user)
  public func remove(_ ids: Set<String>) async throws {
    try validateAudiobookIDs(ids)
    try await performLibraryOperation(
      .delete, endpoint: "/me/audiobooks", ids: ids, client: client)
  }

  /// Check if one or more audiobooks are already saved in the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Returns: An array of booleans corresponding to the IDs requested.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-audiobooks)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateAudiobookIDs(ids)
    return
      try await client
      .get("/me/audiobooks/contains")
      .query("ids", ids.sorted().joined(separator: ","))
      .decode([Bool].self)
  }
}

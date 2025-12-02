import Foundation

private typealias SeveralAudiobooksWrapper = ArrayWrapper<Audiobook?>

private let MAXIMUM_AUDIOBOOK_ID_BATCH_SIZE = 50

/// A service for fetching and managing Spotify Audiobook resources and their chapters.
public struct AudiobooksService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
  init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension AudiobooksService {
  private func validateAudiobookIDs(_ ids: Set<String>) throws {
    try validateMaxIdCount(MAXIMUM_AUDIOBOOK_ID_BATCH_SIZE, for: ids)
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
  /// - Throws: `SpotifyError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
  public func get(_ id: String, market: String? = nil) async throws -> Audiobook {
    let query = makeMarketQueryItems(from: market)
    let request = SpotifyRequest<Audiobook>.get("/audiobooks/\(id)", query: query)
    return try await client.perform(request)
  }

  /// Get Spotify catalog information for several audiobooks identified by their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `Audiobook` objects (may contain nil for invalid IDs).
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-audiobooks)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Audiobook?] {
    try validateAudiobookIDs(ids)
    let query =
      [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
      + makeMarketQueryItems(from: market)
    let request = SpotifyRequest<SeveralAudiobooksWrapper>.get("/audiobooks", query: query)
    return try await client.perform(request).items
  }

  /// Get Spotify catalog information about an audiobook's chapters.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the audiobook.
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A paginated list of `SimplifiedChapter` items.
  /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-audiobook-chapters)
  public func chapters(
    for id: String,
    limit: Int = 20,
    offset: Int = 0,
    market: String? = nil
  ) async throws -> Page<SimplifiedChapter> {
    try validateLimit(limit)
    let query = makePagedMarketQuery(limit: limit, offset: offset, market: market)
    let request = SpotifyRequest<Page<SimplifiedChapter>>.get(
      "/audiobooks/\(id)/chapters", query: query)
    return try await client.perform(request)
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
  /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-audiobooks)
  public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAudiobook> {
    try validateLimit(limit)
    let query = makePaginationQuery(limit: limit, offset: offset)
    let request = SpotifyRequest<Page<SavedAudiobook>>.get("/me/audiobooks", query: query)
    return try await client.perform(request)
  }

  /// Save one or more audiobooks to the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-audiobooks-user)
  public func save(_ ids: Set<String>) async throws {
    try validateAudiobookIDs(ids)
    try await performLibraryOperation(.put, endpoint: "/me/audiobooks", ids: ids, client: client)
  }

  /// Remove one or more audiobooks from the Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-audiobooks-user)
  public func remove(_ ids: Set<String>) async throws {
    try validateAudiobookIDs(ids)
    try await performLibraryOperation(.delete, endpoint: "/me/audiobooks", ids: ids, client: client)
  }

  /// Check if one or more audiobooks are already saved in the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Returns: An array of booleans corresponding to the IDs requested.
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-audiobooks)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateAudiobookIDs(ids)
    let query = [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
    let request = SpotifyRequest<[Bool]>.get("/me/audiobooks/contains", query: query)
    return try await client.perform(request)
  }
}

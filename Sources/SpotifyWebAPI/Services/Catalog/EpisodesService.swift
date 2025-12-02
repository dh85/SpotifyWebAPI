import Foundation

private typealias SeveralEpisodesWrapper = ArrayWrapper<Episode>

private let MAXIMUM_EPISODE_ID_BATCH_SIZE = 50

/// A service for fetching and managing Spotify Episode (Podcast Episode) resources.
public struct EpisodesService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>
  init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension EpisodesService {
  private func validateEpisodeIDs(_ ids: Set<String>) throws {
    try validateMaxIdCount(MAXIMUM_EPISODE_ID_BATCH_SIZE, for: ids)
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
  /// - Throws: `SpotifyError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-episode)
  public func get(_ id: String, market: String? = nil) async throws -> Episode {
    let query = makeMarketQueryItems(from: market)
    let request = SpotifyRequest<Episode>.get("/episodes/\(id)", query: query)
    return try await client.perform(request)
  }

  /// Get Spotify catalog information for several episodes identified by their Spotify IDs.
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 50).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `Episode` objects.
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-episodes)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Episode] {
    try validateEpisodeIDs(ids)
    let query =
      [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
      + makeMarketQueryItems(from: market)
    let request = SpotifyRequest<SeveralEpisodesWrapper>.get("/episodes", query: query)
    return try await client.perform(request).items
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
  /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-episodes)
  public func saved(limit: Int = 20, offset: Int = 0, market: String? = nil) async throws -> Page<
    SavedEpisode
  > {
    try validateLimit(limit)
    let query = makePagedMarketQuery(limit: limit, offset: offset, market: market)
    let request = SpotifyRequest<Page<SavedEpisode>>.get("/me/episodes", query: query)
    return try await client.perform(request)
  }

  /// Save one or more episodes to the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-episodes-user)
  public func save(_ ids: Set<String>) async throws {
    try validateEpisodeIDs(ids)
    try await performLibraryOperation(.put, endpoint: "/me/episodes", ids: ids, client: client)
  }

  /// Remove one or more episodes from the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-episodes-user)
  public func remove(_ ids: Set<String>) async throws {
    try validateEpisodeIDs(ids)
    try await performLibraryOperation(.delete, endpoint: "/me/episodes", ids: ids, client: client)
  }

  /// Check if one or more episodes are already saved in the current Spotify user's library.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 50).
  /// - Returns: An array of booleans corresponding to the IDs requested.
  /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-episodes)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateEpisodeIDs(ids)
    let query = [URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ","))]
    let request = SpotifyRequest<[Bool]>.get("/me/episodes/contains", query: query)
    return try await client.perform(request)
  }
}

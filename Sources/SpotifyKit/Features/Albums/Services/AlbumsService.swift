import Foundation

private typealias SeveralAlbumsWrapper = ArrayWrapper<Album>

/// A service for fetching and managing Spotify Album resources.
///
/// ## Overview
///
/// AlbumsService provides access to:
/// - Album catalog information
/// - Album tracks
/// - User's saved albums ("Your Music" library)
/// - Batch operations for saving/removing albums
///
/// ## Examples
///
/// ### Get Album Details
/// ```swift
/// let album = try await client.albums.get("4aawyAB9vmqN3uQ7FjRGTy")
/// print("\(album.name) by \(album.artistNames)")
/// print("Released: \(album.releaseDate)")
/// print("Tracks: \(album.tracks.total)")
/// ```
///
/// ### Get Multiple Albums
/// ```swift
/// let albumIDs: Set<String> = ["album1", "album2", "album3"]
/// let albums = try await client.albums.several(ids: albumIDs)
/// for album in albums {
///     print(album.name)
/// }
/// ```
///
/// ### Save Albums to Library
/// ```swift
/// // Save single album
/// try await client.albums.save(["4aawyAB9vmqN3uQ7FjRGTy"])
///
/// // Save many albums (automatically chunked into batches of 20)
/// let manyAlbums = ["album1", "album2", ...] // 100 albums
/// try await client.albums.saveAll(manyAlbums)
/// ```
///
/// ### Check if Albums are Saved
/// ```swift
/// let albumIDs: Set<String> = ["album1", "album2", "album3"]
/// let saved = try await client.albums.checkSaved(albumIDs)
/// for (id, isSaved) in zip(albumIDs, saved) {
///     print("\(id): \(isSaved ? "✓" : "✗")")
/// }
/// ```
///
/// ## Combine Counterparts
///
/// Prefer publishers? Import Combine and call helpers such as
/// ``AlbumsService/getPublisher(_:market:priority:)`` or
/// ``AlbumsService/savedPublisher(limit:offset:priority:)`` from `AlbumsService+Combine.swift`.
/// These wrappers forward to the async implementations so behavior stays identical.
///
/// - Note: Batch save/remove helpers for user libraries live in `LibraryServiceExtensions.swift`.
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
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
  public func get(_ id: String, market: String? = nil) async throws -> Album {
    return
      try await client
      .get("/albums/\(id)")
      .market(market)
      .decode(Album.self)
  }

  /// Get Spotify catalog information for multiple albums identified by their Spotify IDs.
  /// Corresponds to: `GET /v1/albums`
  ///
  /// - Parameters:
  ///   - ids: A list of Spotify IDs (max 20).
  ///   - market: An ISO 3166-1 alpha-2 country code.
  /// - Returns: A list of `Album` objects.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-albums)
  public func several(ids: Set<String>, market: String? = nil) async throws -> [Album] {
    try validateAlbumIDs(ids)

    let wrapper =
      try await client
      .get("/albums")
      .query("ids", ids.joined(separator: ","))
      .market(market)
      .decode(SeveralAlbumsWrapper.self)
    return wrapper.items
  }

  /// Get Spotify catalog information about an album's tracks.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the album.
  ///   - market: An ISO 3166-1 alpha-2 country code.
  ///   - limit: The number of items to return (1-50). Default: 20.
  ///   - offset: The index of the first item to return. Default: 0.
  /// - Returns: A paginated list of `SimplifiedTrack` items.
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-albums-tracks)
  public func tracks(
    _ id: String,
    market: String? = nil,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> Page<SimplifiedTrack> {
    try validateLimit(limit)

    return
      try await client
      .get("/albums/\(id)/tracks")
      .paginate(limit: limit, offset: offset)
      .market(market)
      .decode(Page<SimplifiedTrack>.self)
  }

  /// Streams an album's tracks page-by-page for batched processing.
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the album.
  ///   - market: Optional market relinking code.
  ///   - pageSize: Desired number of tracks per request (clamped to 1...50). Default: 50.
  ///   - maxPages: Optional limit on pages to emit from the stream.
  /// - Returns: Async sequence yielding raw `Page<SimplifiedTrack>` responses.
  public func streamTrackPages(
    _ id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SimplifiedTrack>, Error> {
    client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
      try await self.tracks(id, market: market, limit: limit, offset: offset)
    }
  }

  /// Streams an album's tracks one-by-one while fetching pages lazily.
  ///
  /// - Parameters mirror ``streamTrackPages(_:market:pageSize:maxPages:)`` but replace `maxPages`
  ///   with `maxItems`.
  public func streamTracks(
    _ id: String,
    market: String? = nil,
    pageSize: Int = 50,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SimplifiedTrack, Error> {
    client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
      try await self.tracks(id, market: market, limit: limit, offset: offset)
    }
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
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-saved-albums)
  public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<SavedAlbum> {
    try validateLimit(limit)

    return
      try await client
      .get("/me/albums")
      .paginate(limit: limit, offset: offset)
      .decode(Page<SavedAlbum>.self)
  }

  /// Fetch all albums saved in the current user's library.
  ///
  /// - Parameter maxItems: Total number of albums to fetch. Default: 5,000. Pass `nil` for unlimited.
  /// - Returns: Array of `SavedAlbum` values aggregated across every page.
  /// - Throws: `SpotifyClientError` if the request fails.
  public func allSavedAlbums(maxItems: Int? = 5000) async throws -> [SavedAlbum] {
    try await savedAlbumsProvider(defaultMaxItems: 5000).all(maxItems: maxItems)
  }

  /// Streams saved albums one at a time, fetching pages lazily.
  ///
  /// - Parameter maxItems: Optional cap on streamed albums. Default: `nil`.
  /// - Returns: Async sequence yielding `SavedAlbum` entries as they are fetched.
  public func streamSavedAlbums(maxItems: Int? = nil) -> AsyncThrowingStream<SavedAlbum, Error> {
    savedAlbumsProvider(defaultMaxItems: nil).stream(maxItems: maxItems)
  }

  /// Streams entire pages of saved albums, useful for batched UI updates or caching.
  ///
  /// - Parameter maxPages: Optional limit on the number of pages to fetch.
  /// - Returns: Async sequence emitting the raw `Page` responses.
  public func streamSavedAlbumPages(maxPages: Int? = nil)
    -> AsyncThrowingStream<Page<SavedAlbum>, Error>
  {
    savedAlbumsProvider(defaultMaxItems: nil).streamPages(maxPages: maxPages)
  }

  private func savedAlbumsProvider(
    defaultMaxItems: Int?
  ) -> AllItemsProvider<Capability, SavedAlbum> {
    client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) {
      limit, offset in
      try await self.saved(limit: limit, offset: offset)
    }
  }

  /// Save one or more albums to the current user's 'Your Music' library.
  /// Corresponds to: `PUT /v1/me/albums`. Requires the `user-library-modify` scope.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 20).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/save-albums-user)
  public func save(_ ids: Set<String>) async throws {
    try validateAlbumIDs(ids)

    try await client
      .put("/me/albums")
      .body(IDsBody(ids: ids))
      .execute()
  }

  /// Remove one or more albums from the current user's 'Your Music' library.
  /// Corresponds to: `DELETE /v1/me/albums`. Requires the `user-library-modify` scope.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 20).
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-albums-user)
  public func remove(_ ids: Set<String>) async throws {
    try validateAlbumIDs(ids)

    try await client
      .delete("/me/albums")
      .body(IDsBody(ids: ids))
      .execute()
  }

  /// Check if one or more albums is already saved in the current Spotify user's 'Your Music' library.
  /// Corresponds to: `GET /v1/me/albums/contains`. Requires the `user-library-read` scope.
  ///
  /// - Parameter ids: A list of Spotify IDs (max 20).
  /// - Returns: An array of booleans corresponding to the IDs requested.
  /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-users-saved-albums)
  public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
    try validateAlbumIDs(ids)

    return
      try await client
      .get("/me/albums/contains")
      .query("ids", ids.joined(separator: ","))
      .decode([Bool].self)
  }
}

// MARK: - Helper Methods

extension AlbumsService: ServiceIDValidating {
  static var maxBatchSize: Int { SpotifyAPILimits.Albums.batchSize }

  fileprivate func validateAlbumIDs(_ ids: Set<String>) throws {
    try validateIDs(ids)
  }
}

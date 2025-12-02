import Foundation

/// A fluent builder for constructing Spotify search queries with type-safe chaining.
///
/// ## Overview
///
/// `SearchQueryBuilder` provides a fluent API for building complex search queries
/// without dealing with string concatenation or query syntax errors.
///
/// ## Examples
///
/// ### Basic Search
/// ```swift
/// let results = try await client.search
///     .query("Bohemian Rhapsody")
///     .forTracks()
///     .withLimit(10)
///     .execute()
/// ```
///
/// ### Advanced Filtering
/// ```swift
/// let results = try await client.search
///     .query("rock")
///     .forTracks()
///     .byArtist("Queen")
///     .inYear(1975...1980)
///     .inMarket("US")
///     .withLimit(20)
///     .execute()
/// ```
///
/// ### Multi-Type Search
/// ```swift
/// let results = try await client.search
///     .query("Taylor Swift")
///     .forTypes([.artist, .album, .track])
///     .inMarket("US")
///     .execute()
/// ```
///
/// ### Genre Filtering
/// ```swift
/// let results = try await client.search
///     .query("party")
///     .forTracks()
///     .withGenre("pop")
///     .withLimit(50)
///     .execute()
/// ```
///
/// ### Combine Publisher (iOS 13+, macOS 10.15+)
/// ```swift
/// client.search
///     .query("rock")
///     .byArtist("Queen")
///     .forTracks()
///     .executePublisher()
///     .sink(
///         receiveCompletion: { completion in
///             if case .failure(let error) = completion {
///                 print("Error: \(error)")
///             }
///         },
///         receiveValue: { results in
///             if let tracks = results.tracks {
///                 print("Found \(tracks.items.count) tracks")
///             }
///         }
///     )
///     .store(in: &cancellables)
/// ```
public struct SearchQueryBuilder<Capability: PublicSpotifyCapability>: Sendable {
  private let client: SpotifyClient<Capability>
  private var queryComponents: [String] = []
  private var searchTypes: Set<SearchType> = []
  private var market: String?
  private var limit: Int = 20
  private var offset: Int = 0
  private var includeExternal: ExternalContent?

  init(client: SpotifyClient<Capability>) {
    self.client = client
  }

  // MARK: - Query Building

  /// Sets the base search query.
  ///
  /// - Parameter text: The search keywords.
  /// - Returns: A new builder with the query set.
  public func query(_ text: String) -> Self {
    var builder = self
    builder.queryComponents.append(text)
    return builder
  }

  /// Filters by artist name.
  ///
  /// - Parameter artist: The artist name to filter by.
  /// - Returns: A new builder with the artist filter applied.
  public func byArtist(_ artist: String) -> Self {
    var builder = self
    builder.queryComponents.append("artist:\"\(artist)\"")
    return builder
  }

  /// Filters by album name.
  ///
  /// - Parameter album: The album name to filter by.
  /// - Returns: A new builder with the album filter applied.
  public func inAlbum(_ album: String) -> Self {
    var builder = self
    builder.queryComponents.append("album:\"\(album)\"")
    return builder
  }

  /// Filters by track name.
  ///
  /// - Parameter track: The track name to filter by.
  /// - Returns: A new builder with the track filter applied.
  public func withTrackName(_ track: String) -> Self {
    var builder = self
    builder.queryComponents.append("track:\"\(track)\"")
    return builder
  }

  /// Filters by release year.
  ///
  /// - Parameter year: The year to filter by.
  /// - Returns: A new builder with the year filter applied.
  public func inYear(_ year: Int) -> Self {
    var builder = self
    builder.queryComponents.append("year:\(year)")
    return builder
  }

  /// Filters by year range.
  ///
  /// - Parameter range: The year range to filter by.
  /// - Returns: A new builder with the year range filter applied.
  public func inYear(_ range: ClosedRange<Int>) -> Self {
    var builder = self
    builder.queryComponents.append("year:\(range.lowerBound)-\(range.upperBound)")
    return builder
  }

  /// Filters by genre.
  ///
  /// - Parameter genre: The genre to filter by.
  /// - Returns: A new builder with the genre filter applied.
  public func withGenre(_ genre: String) -> Self {
    var builder = self
    builder.queryComponents.append("genre:\"\(genre)\"")
    return builder
  }

  /// Filters by ISRC code.
  ///
  /// - Parameter isrc: The ISRC code to filter by.
  /// - Returns: A new builder with the ISRC filter applied.
  public func withISRC(_ isrc: String) -> Self {
    var builder = self
    builder.queryComponents.append("isrc:\(isrc)")
    return builder
  }

  /// Filters by UPC code.
  ///
  /// - Parameter upc: The UPC code to filter by.
  /// - Returns: A new builder with the UPC filter applied.
  public func withUPC(_ upc: String) -> Self {
    var builder = self
    builder.queryComponents.append("upc:\(upc)")
    return builder
  }

  /// Adds a custom filter to the query.
  ///
  /// - Parameter filter: A custom filter string (e.g., "tag:new").
  /// - Returns: A new builder with the custom filter applied.
  public func withFilter(_ filter: String) -> Self {
    var builder = self
    builder.queryComponents.append(filter)
    return builder
  }

  // MARK: - Search Types

  /// Searches for tracks only.
  ///
  /// - Returns: A new builder configured to search for tracks.
  public func forTracks() -> Self {
    var builder = self
    builder.searchTypes = [.track]
    return builder
  }

  /// Searches for albums only.
  ///
  /// - Returns: A new builder configured to search for albums.
  public func forAlbums() -> Self {
    var builder = self
    builder.searchTypes = [.album]
    return builder
  }

  /// Searches for artists only.
  ///
  /// - Returns: A new builder configured to search for artists.
  public func forArtists() -> Self {
    var builder = self
    builder.searchTypes = [.artist]
    return builder
  }

  /// Searches for playlists only.
  ///
  /// - Returns: A new builder configured to search for playlists.
  public func forPlaylists() -> Self {
    var builder = self
    builder.searchTypes = [.playlist]
    return builder
  }

  /// Searches for shows only.
  ///
  /// - Returns: A new builder configured to search for shows.
  public func forShows() -> Self {
    var builder = self
    builder.searchTypes = [.show]
    return builder
  }

  /// Searches for episodes only.
  ///
  /// - Returns: A new builder configured to search for episodes.
  public func forEpisodes() -> Self {
    var builder = self
    builder.searchTypes = [.episode]
    return builder
  }

  /// Searches for audiobooks only.
  ///
  /// - Returns: A new builder configured to search for audiobooks.
  public func forAudiobooks() -> Self {
    var builder = self
    builder.searchTypes = [.audiobook]
    return builder
  }

  /// Searches for multiple content types.
  ///
  /// - Parameter types: The set of content types to search for.
  /// - Returns: A new builder configured to search for the specified types.
  public func forTypes(_ types: Set<SearchType>) -> Self {
    var builder = self
    builder.searchTypes = types
    return builder
  }

  // MARK: - Market & Limits

  /// Restricts results to a specific market.
  ///
  /// - Parameter market: An ISO 3166-1 alpha-2 country code (e.g., "US", "GB").
  /// - Returns: A new builder with the market restriction applied.
  public func inMarket(_ market: String) -> Self {
    var builder = self
    builder.market = market
    return builder
  }

  /// Sets the maximum number of results to return per type.
  ///
  /// - Parameter limit: The maximum number of results (1-50).
  /// - Returns: A new builder with the limit set.
  public func withLimit(_ limit: Int) -> Self {
    var builder = self
    builder.limit = limit
    return builder
  }

  /// Sets the offset for pagination.
  ///
  /// - Parameter offset: The index of the first result to return.
  /// - Returns: A new builder with the offset set.
  public func withOffset(_ offset: Int) -> Self {
    var builder = self
    builder.offset = offset
    return builder
  }

  /// Includes externally hosted audio content.
  ///
  /// - Parameter external: The external content type to include.
  /// - Returns: A new builder configured to include external content.
  public func includeExternal(_ external: ExternalContent) -> Self {
    var builder = self
    builder.includeExternal = external
    return builder
  }

  // MARK: - Execution

  /// Executes the search query.
  ///
  /// - Returns: Search results containing the requested content types.
  /// - Throws: `SpotifyClientError` if the request fails or parameters are invalid.
  public func execute() async throws -> SearchResults {
    guard !searchTypes.isEmpty else {
      throw SpotifyClientError.invalidRequest(reason: "Must specify at least one search type")
    }

    let query = queryComponents.joined(separator: " ")
    guard !query.isEmpty else {
      throw SpotifyClientError.invalidRequest(reason: "Search query cannot be empty")
    }

    return try await client.search.execute(
      query: query,
      types: searchTypes,
      market: market,
      limit: limit,
      offset: offset,
      includeExternal: includeExternal
    )
  }

  /// Executes the search and returns only tracks.
  ///
  /// - Returns: A page of tracks matching the search criteria.
  /// - Throws: `SpotifyClientError` if the request fails or no tracks are found.
  public func executeTracks() async throws -> Page<Track> {
    let results = try await forTracks().execute()
    guard let tracks = results.tracks else {
      throw SpotifyClientError.invalidRequest(reason: "No track results returned")
    }
    return tracks
  }

  /// Executes the search and returns only albums.
  ///
  /// - Returns: A page of albums matching the search criteria.
  /// - Throws: `SpotifyClientError` if the request fails or no albums are found.
  public func executeAlbums() async throws -> Page<SimplifiedAlbum> {
    let results = try await forAlbums().execute()
    guard let albums = results.albums else {
      throw SpotifyClientError.invalidRequest(reason: "No album results returned")
    }
    return albums
  }

  /// Executes the search and returns only artists.
  ///
  /// - Returns: A page of artists matching the search criteria.
  /// - Throws: `SpotifyClientError` if the request fails or no artists are found.
  public func executeArtists() async throws -> Page<Artist> {
    let results = try await forArtists().execute()
    guard let artists = results.artists else {
      throw SpotifyClientError.invalidRequest(reason: "No artist results returned")
    }
    return artists
  }

  /// Executes the search and returns only playlists.
  ///
  /// - Returns: A page of playlists matching the search criteria.
  /// - Throws: `SpotifyClientError` if the request fails or no playlists are found.
  public func executePlaylists() async throws -> Page<SimplifiedPlaylist> {
    let results = try await forPlaylists().execute()
    guard let playlists = results.playlists else {
      throw SpotifyClientError.invalidRequest(reason: "No playlist results returned")
    }
    return playlists
  }
}

// MARK: - Combine Support

#if canImport(Combine)
  import Combine

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension SearchQueryBuilder {
    /// Executes the search query and returns a Combine publisher.
    ///
    /// - Parameter priority: Optional task priority for the async operation.
    /// - Returns: A publisher that emits search results or an error.
    public func executePublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      SearchResults, Error
    > {
      guard !searchTypes.isEmpty else {
        return Fail(
          error: SpotifyClientError.invalidRequest(
            reason: "Must specify at least one search type")
        )
        .eraseToAnyPublisher()
      }

      let query = queryComponents.joined(separator: " ")
      guard !query.isEmpty else {
        return Fail(
          error: SpotifyClientError.invalidRequest(reason: "Search query cannot be empty")
        )
        .eraseToAnyPublisher()
      }

      return client.search.executePublisher(
        query: query,
        types: searchTypes,
        market: market,
        limit: limit,
        offset: offset,
        includeExternal: includeExternal,
        priority: priority
      )
    }

    /// Executes the search and returns only tracks as a Combine publisher.
    ///
    /// - Parameter priority: Optional task priority for the async operation.
    /// - Returns: A publisher that emits a page of tracks or an error.
    public func executeTracksPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      Page<Track>, Error
    > {
      forTracks().executePublisher(priority: priority)
        .tryMap { results in
          guard let tracks = results.tracks else {
            throw SpotifyClientError.invalidRequest(reason: "No track results returned")
          }
          return tracks
        }
        .eraseToAnyPublisher()
    }

    /// Executes the search and returns only albums as a Combine publisher.
    ///
    /// - Parameter priority: Optional task priority for the async operation.
    /// - Returns: A publisher that emits a page of albums or an error.
    public func executeAlbumsPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      Page<SimplifiedAlbum>, Error
    > {
      forAlbums().executePublisher(priority: priority)
        .tryMap { results in
          guard let albums = results.albums else {
            throw SpotifyClientError.invalidRequest(reason: "No album results returned")
          }
          return albums
        }
        .eraseToAnyPublisher()
    }

    /// Executes the search and returns only artists as a Combine publisher.
    ///
    /// - Parameter priority: Optional task priority for the async operation.
    /// - Returns: A publisher that emits a page of artists or an error.
    public func executeArtistsPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      Page<Artist>, Error
    > {
      forArtists().executePublisher(priority: priority)
        .tryMap { results in
          guard let artists = results.artists else {
            throw SpotifyClientError.invalidRequest(
              reason: "No artist results returned")
          }
          return artists
        }
        .eraseToAnyPublisher()
    }

    /// Executes the search and returns only playlists as a Combine publisher.
    ///
    /// - Parameter priority: Optional task priority for the async operation.
    /// - Returns: A publisher that emits a page of playlists or an error.
    public func executePlaylistsPublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      Page<SimplifiedPlaylist>, Error
    > {
      forPlaylists().executePublisher(priority: priority)
        .tryMap { results in
          guard let playlists = results.playlists else {
            throw SpotifyClientError.invalidRequest(
              reason: "No playlist results returned")
          }
          return playlists
        }
        .eraseToAnyPublisher()
    }
  }
#endif

// MARK: - SearchService Extension

extension SearchService where Capability: PublicSpotifyCapability {
  /// Creates a new search query builder.
  ///
  /// Use this to build complex search queries with a fluent API.
  ///
  /// ## Example
  ///
  /// ```swift
  /// let results = try await client.search
  ///     .builder()
  ///     .query("rock")
  ///     .forTracks()
  ///     .byArtist("Queen")
  ///     .inYear(1970...1980)
  ///     .execute()
  /// ```
  public func builder() -> SearchQueryBuilder<Capability> {
    SearchQueryBuilder(client: client)
  }
}

// MARK: - Convenience Extensions

extension SearchService where Capability: PublicSpotifyCapability {
  /// Starts building a search query with the specified text.
  ///
  /// This is a convenience method that creates a builder and sets the query in one call.
  ///
  /// ## Example
  ///
  /// ```swift
  /// let results = try await client.search
  ///     .query("Bohemian Rhapsody")
  ///     .forTracks()
  ///     .execute()
  /// ```
  public func query(_ text: String) -> SearchQueryBuilder<Capability> {
    builder().query(text)
  }
}

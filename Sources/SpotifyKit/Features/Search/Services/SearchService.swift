import Foundation

/// A service providing access to Spotify's global search functionality.
///
/// ## Overview
///
/// SearchService provides a fluent builder API for type-safe, chainable search queries across multiple Spotify content types:
/// - Albums
/// - Artists
/// - Playlists
/// - Tracks
/// - Shows (podcasts)
/// - Episodes
/// - Audiobooks
///
/// ## Examples
///
/// ### Simple Search
/// ```swift
/// let tracks = try await client.search
///     .query("Bohemian Rhapsody")
///     .forTracks()
///     .execute()
/// ```
///
/// ### Advanced Filtered Search
/// ```swift
/// let results = try await client.search
///     .query("rock")
///     .byArtist("Queen")
///     .inYear(1975...1980)
///     .withGenre("rock")
///     .forTracks()
///     .inMarket("US")
///     .withLimit(20)
///     .execute()
/// ```
///
/// ### Direct Result Extraction
/// ```swift
/// let tracks = try await client.search
///     .query("Taylor Swift")
///     .executeTracks()
/// ```
///
/// ### Multi-Type Search
/// ```swift
/// let results = try await client.search
///     .query("Queen")
///     .forTypes([.artist, .album, .track])
///     .withLimit(5)
///     .execute()
///
/// if let artists = results.artists?.items {
///     print("Artists: \(artists.map(\.name).joined(separator: ", "))")
/// }
/// ```
///
/// ### Market-Specific Search
/// ```swift
/// let results = try await client.search
///     .query("Taylor Swift")
///     .forTypes([.track, .album])
///     .inMarket("US")
///     .withLimit(10)
///     .execute()
/// ```
///
/// ### Combine Publisher (iOS 13+, macOS 10.15+)
/// ```swift
/// client.search
///     .query("Bohemian Rhapsody")
///     .forTracks()
///     .executeTracksPublisher()
///     .sink(
///         receiveCompletion: { _ in },
///         receiveValue: { tracks in
///             print("Found \(tracks.items.count) tracks")
///         }
///     )
///     .store(in: &cancellables)
/// ```
///
/// ## Search Query Syntax
///
/// The builder provides methods for common filters, or you can use raw Spotify query syntax:
/// - `artist:name` - Filter by artist name
/// - `album:name` - Filter by album name
/// - `track:name` - Filter by track name
/// - `year:YYYY` or `year:YYYY-YYYY` - Filter by year or year range
/// - `genre:name` - Filter by genre
/// - `isrc:code` - Filter by ISRC code
/// - `upc:code` - Filter by UPC code
///
/// [Spotify Search Guide](https://developer.spotify.com/documentation/web-api/reference/search)
public struct SearchService<Capability: Sendable>: Sendable {
  let client: SpotifyClient<Capability>

  init(client: SpotifyClient<Capability>) {
    self.client = client
  }
}

// MARK: - Internal API (used by SearchQueryBuilder)

extension SearchService where Capability: PublicSpotifyCapability {
  /// Internal method used by SearchQueryBuilder to execute search requests.
  /// Corresponds to: `GET /v1/search`
  internal func execute(
    query: String,
    types: Set<SearchType>,
    market: String? = nil,
    limit: Int = 20,
    offset: Int = 0,
    includeExternal: ExternalContent? = nil
  ) async throws -> SearchResults {
    try validateLimit(limit)
    var builder =
      client
      .get("/search")
      .query("q", query)
      .query("type", types.spotifyQueryValue)
      .paginate(limit: limit, offset: offset)
      .market(market)

    if let includeExternal = includeExternal {
      builder = builder.query("include_external", includeExternal.rawValue)
    }

    return try await builder.decode(SearchResults.self)
  }
}

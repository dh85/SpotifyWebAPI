import Foundation

/// A service providing access to Spotify's global search functionality.
///
/// ## Overview
///
/// SearchService allows searching across multiple Spotify content types:
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
/// ### Search for Tracks
/// ```swift
/// let results = try await client.search.execute(
///     query: "Bohemian Rhapsody",
///     types: [.track],
///     limit: 10
/// )
///
/// if let tracks = results.tracks?.items {
///     for track in tracks {
///         print("\(track.name) by \(track.artistNames)")
///     }
/// }
/// ```
///
/// ### Search Multiple Types
/// ```swift
/// let results = try await client.search.execute(
///     query: "Queen",
///     types: [.artist, .album, .track],
///     limit: 5
/// )
///
/// if let artists = results.artists?.items {
///     print("Artists: \(artists.map(\.name).joined(separator: ", "))")
/// }
/// if let albums = results.albums?.items {
///     print("Albums: \(albums.map(\.name).joined(separator: ", "))")
/// }
/// if let tracks = results.tracks?.items {
///     print("Tracks: \(tracks.map(\.name).joined(separator: ", "))")
/// }
/// ```
///
/// ### Advanced Search with Filters
/// ```swift
/// // Search for albums by specific artist
/// let results = try await client.search.execute(
///     query: "album:A Night at the Opera artist:Queen",
///     types: [.album]
/// )
///
/// // Search for tracks in a year range
/// let results = try await client.search.execute(
///     query: "year:2020-2023 genre:rock",
///     types: [.track],
///     limit: 20
/// )
/// ```
///
/// ### Market-Specific Search
/// ```swift
/// // Only return content available in the US market
/// let results = try await client.search.execute(
///     query: "Taylor Swift",
///     types: [.track, .album],
///     market: "US",
///     limit: 10
/// )
/// ```
///
/// ## Search Query Syntax
///
/// Spotify supports advanced search filters:
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

// MARK: - Public Access

extension SearchService where Capability: PublicSpotifyCapability {

    /// Search for albums, artists, playlists, tracks, shows, episodes, or audiobooks.
    /// Corresponds to: `GET /v1/search`
    ///
    /// - Parameters:
    ///   - query: Search query keywords and optional field filters and operators.
    ///   - types: A set of item types to search across (album, artist, playlist, track, show, episode, audiobook).
    ///   - market: An ISO 3166-1 alpha-2 country code. If provided, only content available in that market is returned.
    ///   - limit: The maximum number of results to return per type (1-50). Default: 20.
    ///   - offset: The index of the first result to return. Default: 0.
    ///   - includeExternal: If specified, the response will include any relevant audio content that is hosted externally.
    /// - Returns: A `SearchResults` object containing paginated results for the requested types.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/search)
    public func execute(
        query: String,
        types: Set<SearchType>,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        includeExternal: ExternalContent? = nil
    ) async throws -> SearchResults {
        try validateLimit(limit)

        let queryItems: [URLQueryItem] =
            [
                .init(name: "q", value: query),
                .init(name: "type", value: types.spotifyQueryValue),
            ] + makePaginationQuery(limit: limit, offset: offset)
            + makeMarketQueryItems(from: market)
            + makeIncludeExternalQueryItems(from: includeExternal)

        let request = SpotifyRequest<SearchResults>.get("/search", query: queryItems)
        return try await client.perform(request)
    }
}

// MARK: - Helper Methods

extension SearchService {
    fileprivate func makeIncludeExternalQueryItems(from includeExternal: ExternalContent?) -> [URLQueryItem]
    {
        guard let includeExternal else { return [] }
        return [.init(name: "include_external", value: includeExternal.rawValue)]
    }
}

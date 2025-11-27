import Foundation

private typealias SeveralArtistsWrapper = ArrayWrapper<Artist>
private typealias TopTracksWrapper = ArrayWrapper<Track>

/// A service for fetching and managing Spotify Artist resources.
///
/// ## Overview
///
/// ArtistsService provides access to:
/// - Artist catalog information
/// - Artist albums and discography
/// - Artist top tracks by market
/// - Related artists
///
/// ## Examples
///
/// ### Get Artist Details
/// ```swift
/// let artist = try await client.artists.get("0OdUWJ0sBjDrqHygGUXeCF")
/// print("\(artist.name)")
/// print("Genres: \(artist.genres.joined(separator: ", "))")
/// print("Popularity: \(artist.popularity)/100")
/// print("Followers: \(artist.followers.total)")
/// ```
///
/// ### Get Multiple Artists
/// ```swift
/// let artistIDs: Set<String> = ["artist1", "artist2", "artist3"]
/// let artists = try await client.artists.several(ids: artistIDs)
/// for artist in artists {
///     print("\(artist.name) - \(artist.genres.joined(separator: ", "))")
/// }
/// ```
///
/// ### Get Artist's Albums
/// ```swift
/// // Get all album types
/// let albums = try await client.artists.albums(
///     for: "0OdUWJ0sBjDrqHygGUXeCF",
///     limit: 50
/// )
///
/// // Filter by album type
/// let albumsOnly = try await client.artists.albums(
///     for: "0OdUWJ0sBjDrqHygGUXeCF",
///     includeGroups: [.album],
///     limit: 20
/// )
///
/// // Get singles and compilations
/// let singlesAndCompilations = try await client.artists.albums(
///     for: "0OdUWJ0sBjDrqHygGUXeCF",
///     includeGroups: [.single, .compilation]
/// )
/// ```
///
/// ### Get Artist's Top Tracks
/// ```swift
/// // Get top tracks for US market
/// let topTracks = try await client.artists.topTracks(
///     for: "0OdUWJ0sBjDrqHygGUXeCF",
///     market: "US"
/// )
///
/// print("Top tracks:")
/// for (index, track) in topTracks.enumerated() {
///     print("\(index + 1). \(track.name) - \(track.durationFormatted)")
/// }
/// ```
///
/// ## Album Groups
///
/// When fetching artist albums, you can filter by:
/// - `.album` - Studio albums
/// - `.single` - Singles and EPs
/// - `.compilation` - Compilation albums
/// - `.appearsOn` - Albums the artist appears on
///
/// ## Combine Counterparts
///
/// Publisher variants such as `getPublisher` and
/// ``ArtistsService/albumsPublisher(for:includeGroups:market:limit:offset:priority:)`` live in
/// `ArtistsService+Combine.swift`. They call into these async methods so you can switch between
/// async/await and Combine without relearning the API surface.
public struct ArtistsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access
extension ArtistsService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single artist identified by their unique Spotify ID.
    ///
    /// - Parameter id: The Spotify ID for the artist.
    /// - Returns: A full `Artist` object.
    /// - Throws: `SpotifyClientError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artist)
    public func get(_ id: String) async throws -> Artist {
        return try await client
            .get("/artists/\(id)")
            .decode(Artist.self)
    }

    /// Get Spotify catalog information for several artists based on their Spotify IDs.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: A list of `Artist` objects.
    /// - Throws: `SpotifyClientError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-artists)
    public func several(ids: Set<String>) async throws -> [Artist] {
        try validateArtistIDs(ids)
        
        let wrapper = try await client
            .get("/artists")
            .query("ids", ids.joined(separator: ","))
            .decode(SeveralArtistsWrapper.self)
        return wrapper.items
    }

    /// Get Spotify catalog information about an artist's albums.
    ///
    /// - Parameters:
    ///   - artistId: The Spotify ID for the artist.
    ///   - groups: Filter by album types.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SimplifiedAlbum` items.
    /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artists-albums)
    public func albums(
        artistId: String,
        groups: Set<AlbumGroup>? = nil,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {
        try validateLimit(limit)
        
        var builder = client
            .get("/artists/\(artistId)/albums")
            .market(market)
            .paginate(limit: limit, offset: offset)
        
        if let groups = groups, !groups.isEmpty {
            builder = builder.query(
                "include_groups",
                groups.map(\.rawValue).sorted().joined(separator: ",")
            )
        }
        
        return try await builder.decode(Page<SimplifiedAlbum>.self)
    }

    /// Stream full pages of an artist's albums for incremental processing.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Optional album type filters (albums, singles, etc.).
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - pageSize: Desired number of albums per page (clamped to 1...50). Default: 50.
    ///   - maxPages: Optional limit on number of pages to emit.
    /// - Returns: An async sequence yielding `Page<SimplifiedAlbum>` values as they are fetched.
    public func streamAlbumPages(
        for id: String,
        includeGroups: Set<AlbumGroup>? = nil,
        market: String? = nil,
        pageSize: Int = 50,
        maxPages: Int? = nil
    ) -> AsyncThrowingStream<Page<SimplifiedAlbum>, Error> {
        client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
            try await self.albums(
                artistId: id,
                groups: includeGroups,
                market: market,
                limit: limit,
                offset: offset
            )
        }
    }

    /// Streams individual albums from an artist discography.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Optional album filters.
    ///   - market: Optional market code.
    ///   - pageSize: Desired request size (clamped 1...50). Default: 50.
    ///   - maxItems: Optional cap on emitted albums.
    public func streamAlbums(
        for id: String,
        includeGroups: Set<AlbumGroup>? = nil,
        market: String? = nil,
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<SimplifiedAlbum, Error> {
        client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
            try await self.albums(
                artistId: id,
                groups: includeGroups,
                market: market,
                limit: limit,
                offset: offset
            )
        }
    }

    /// Get Spotify catalog information about an artist's top tracks by country.
    ///
    /// - Parameters:
    ///   - artistId: The Spotify ID for the artist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `Track` objects.
    /// - Throws: `SpotifyClientError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artists-top-tracks)
    public func topTracks(artistId: String, market: String) async throws -> [Track] {
        let wrapper = try await client
            .get("/artists/\(artistId)/top-tracks")
            .query("market", market)
            .decode(TopTracksWrapper.self)
        return wrapper.items
    }
}

// MARK: - Helper Methods

extension ArtistsService: ServiceIDValidating {
    static var maxBatchSize: Int { SpotifyAPILimits.Artists.batchSize }

    fileprivate func validateArtistIDs(_ ids: Set<String>) throws {
        try validateIDs(ids)
    }
}

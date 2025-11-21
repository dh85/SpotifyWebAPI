import Foundation

private typealias SeveralArtistsWrapper = ArrayWrapper<Artist>
private typealias TopTracksWrapper = ArrayWrapper<Track>

private let MAXIMUM_ARTIST_ID_BATCH_SIZE = 50

/// A service for fetching and managing Spotify Artist resources.
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
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artist)
    public func get(_ id: String) async throws -> Artist {
        let request = SpotifyRequest<Artist>.get("/artists/\(id)")
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several artists based on their Spotify IDs.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: A list of `Artist` objects.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-multiple-artists)
    public func several(ids: Set<String>) async throws -> [Artist] {
        try validateArtistIDs(ids)

        let query = [makeIDsQueryItem(from: ids)]
        let request = SpotifyRequest<SeveralArtistsWrapper>.get("/artists", query: query)
        return try await client.perform(request).items
    }

    /// Get Spotify catalog information about an artist's albums.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Filter by album types.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `SimplifiedAlbum` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artists-albums)
    public func albums(
        for id: String,
        includeGroups: Set<AlbumGroup>? = nil,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {
        try validateLimit(limit)

        var query = makePaginationQuery(limit: limit, offset: offset)
        query += makeMarketQueryItems(from: market)

        if let groups = includeGroups, !groups.isEmpty {
            let value = groups.map(\.rawValue).sorted().joined(separator: ",")
            query.append(.init(name: "include_groups", value: value))
        }

        let request = SpotifyRequest<Page<SimplifiedAlbum>>.get(
            "/artists/\(id)/albums", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information about an artist's top tracks by country.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `Track` objects.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artists-top-tracks)
    public func topTracks(for id: String, market: String) async throws -> [Track] {
        let query = [URLQueryItem(name: "market", value: market)]
        let request = SpotifyRequest<TopTracksWrapper>.get(
            "/artists/\(id)/top-tracks", query: query)
        return try await client.perform(request).items
    }
}

// MARK: - Helper Methods

extension ArtistsService {
    fileprivate func validateArtistIDs(_ ids: Set<String>) throws {
        try validateMaxIdCount(MAXIMUM_ARTIST_ID_BATCH_SIZE, for: ids)
    }
}

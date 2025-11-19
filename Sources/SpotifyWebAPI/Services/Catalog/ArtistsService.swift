import Foundation

private struct SeveralArtistsWrapper: Decodable { let artists: [Artist] }
private struct TopTracksWrapper: Decodable { let tracks: [Track] }

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

    /// Get Spotify catalog information for a single artist.
    ///
    /// Corresponds to: `GET /v1/artists/{id}`.
    ///
    /// - Parameter id: The Spotify ID for the artist.
    /// - Returns: A full ``Artist`` object.
    public func get(_ id: String) async throws -> Artist {
        let request = SpotifyRequest<Artist>.get("/artists/\(id)")
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several artists based on their Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/artists`.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the artists (max 50).
    /// - Returns: A list of full ``Artist`` objects.
    public func several(ids: Set<String>) async throws -> [Artist] {
        try validateMaxIdCount(MAXIMUM_ARTIST_ID_BATCH_SIZE, for: ids)

        let query = [makeIDsQueryItem(from: ids)]
        let request = SpotifyRequest<SeveralArtistsWrapper>.get(
            "/artists",
            query: query
        )
        return try await client.perform(request).artists
    }

    /// Get Spotify catalog information about an artist's albums.
    ///
    /// Corresponds to: `GET /v1/artists/{id}/albums`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Optional. A list of filters to apply (e.g., "album", "single").
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``SimplifiedAlbum`` items.
    public func albums(
        for id: String,
        includeGroups: Set<AlbumGroup>? = nil,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {
        try validateLimit(limit)

        var query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        if let market { query.append(.init(name: "market", value: market)) }
        if let groups = includeGroups, !groups.isEmpty {
            // Set is not ordered, so need to sort it for testing purposes
            let value = groups.map(\.rawValue).sorted().joined(separator: ",")
            query.append(.init(name: "include_groups", value: value))
        }

        let request = SpotifyRequest<Page<SimplifiedAlbum>>.get(
            "/artists/\(id)/albums",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information about an artist's top tracks.
    ///
    /// Corresponds to: `GET /v1/artists/{id}/top-tracks`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - market: An ISO 3166-1 alpha-2 country code. **Required** by API.
    /// - Returns: A list of full ``Track`` objects.
    public func topTracks(for id: String, market: String) async throws
        -> [Track]
    {
        let query = [URLQueryItem(name: "market", value: market)]
        let request = SpotifyRequest<TopTracksWrapper>.get(
            "/artists/\(id)/top-tracks",
            query: query
        )
        return try await client.perform(request).tracks
    }
}

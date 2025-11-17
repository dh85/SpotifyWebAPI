import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single artist.
    ///
    /// Corresponds to: `GET /v1/artists/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    /// - Returns: A full `Artist` object.
    public func artist(
        id: String
    ) async throws -> Artist {

        let endpoint = ArtistsEndpoint.artist(id: id)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Artist.self, url: url)
    }

    /// Get Spotify catalog information for several artists based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/artists`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the artists. Maximum 50 IDs.
    /// - Returns: A list of full `Artist` objects.
    public func artists(
        ids: [String]
    ) async throws -> [Artist] {

        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = ArtistsEndpoint.severalArtists(ids: clampedIDs)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralArtistsResponse.self,
            url: url
        )

        return response.artists
    }

    /// Get Spotify catalog information about an artist's albums.
    ///
    /// Corresponds to: `GET /v1/artists/{id}/albums`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Optional. A list of filters to apply
    ///     (e.g., "album", "single", "appears_on", "compilation").
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedAlbum` items.
    public func artistAlbums(
        id: String,
        includeGroups: [String]? = nil,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = ArtistsEndpoint.artistAlbums(
            id: id,
            includeGroups: includeGroups,
            market: market,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SimplifiedAlbum>.self, url: url)
    }

    /// Get Spotify catalog information about an artist's top tracks.
    ///
    /// Corresponds to: `GET /v1/artists/{id}/top-tracks`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - market: An ISO 3166-1 alpha-2 country code. This is **required**.
    /// - Returns: A list of full `Track` objects.
    public func artistTopTracks(
        id: String,
        market: String
    ) async throws -> [Track] {

        let endpoint = ArtistsEndpoint.artistTopTracks(
            id: id,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            TopTracksResponse.self,
            url: url
        )

        // Return the unwrapped array of tracks
        return response.tracks
    }
}

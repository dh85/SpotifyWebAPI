import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single album.
    ///
    /// Corresponds to: `GET /v1/albums/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Album` object.
    public func album(
        id: String,
        market: String? = nil
    ) async throws -> Album {

        let endpoint = AlbumsEndpoint.album(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Album.self, url: url)
    }

    /// Get Spotify catalog information for several albums based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/albums`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the albums. Maximum 20 IDs.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full `Album` objects.
    public func albums(
        ids: [String],
        market: String? = nil
    ) async throws -> [Album] {

        let endpoint = AlbumsEndpoint.severalAlbums(ids: ids, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralAlbumsResponse.self,
            url: url
        )

        // Return the unwrapped array
        return response.albums
    }

    /// Get Spotify catalog information about an album's tracks.
    ///
    /// Corresponds to: `GET /v1/albums/{id}/tracks`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the album.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedTrack` items.
    public func albumTracks(
        id: String,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedTrack> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = AlbumsEndpoint.albumTracks(
            id: id,
            market: market,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SimplifiedTrack>.self, url: url)
    }

    /// Get a list of new album releases featured in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/new-releases`
    ///
    /// - Parameters:
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedAlbum` items.
    public func newReleases(
        country: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = AlbumsEndpoint.newReleases(
            country: country,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            NewReleasesResponse.self,
            url: url
        )

        // Return the unwrapped page of albums
        return response.albums
    }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get a list of the albums saved in the current Spotify user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/albums`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SavedAlbum` items.
    public func currentUserSavedAlbums(
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SavedAlbum> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = AlbumsEndpoint.currentUserSavedAlbums(
            limit: clampedLimit,
            offset: offset,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SavedAlbum>.self, url: url)
    }

    /// Save one or more albums to the current user's "Your Music" library.
    ///
    /// Corresponds to: `PUT /v1/me/albums`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the albums. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func saveAlbums(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = AlbumsEndpoint.saveAlbumsForCurrentUser()
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = IDsBody(ids: clampedIDs)
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized PUT request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
            body: httpBody,
            contentType: "application/json"
        )

        // A 200 OK response means success. Anything else is an error.
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Remove one or more albums from the current user's "Your Music" library.
    ///
    /// Corresponds to: `DELETE /v1/me/albums`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the albums. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func removeAlbums(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = AlbumsEndpoint.removeAlbumsForCurrentUser()
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body, just like the PUT request
        let body = IDsBody(ids: clampedIDs)
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized DELETE request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "DELETE",
            body: httpBody,
            contentType: "application/json"
        )

        // A 200 OK response means success.
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Check if one or more albums are already saved in the current
    /// user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/albums/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the albums. Maximum 50 IDs.
    /// - Returns: An array of booleans. The booleans are in the same
    ///   order as the IDs requested.
    public func checkSavedAlbums(ids: [String]) async throws -> [Bool] {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else {
            return []  // Return an empty array if no IDs are provided
        }

        let endpoint = AlbumsEndpoint.checkCurrentUserSavedAlbums(
            ids: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans, e.g., [true, false, true]
        return try await requestJSON([Bool].self, url: url)
    }
}

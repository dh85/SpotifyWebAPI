import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single track.
    ///
    /// Corresponds to: `GET /v1/tracks/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the track.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Track` object.
    public func track(
        id: String,
        market: String? = nil
    ) async throws -> Track {

        let endpoint = TracksEndpoint.track(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Track.self, url: url)
    }

    /// Get Spotify catalog information for several tracks based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/tracks`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the tracks. Maximum 50 IDs.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `Track` objects. (Null/invalid tracks are filtered out).
    public func tracks(
        ids: [String],
        market: String? = nil
    ) async throws -> [Track] {

        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = TracksEndpoint.severalTracks(
            ids: clampedIDs,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralTracksResponse.self,
            url: url
        )

        // Filter out any nils returned by the API for invalid IDs
        return response.tracks.compactMap { $0 }
    }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get a list of the songs saved in the current Spotify user's "Liked Songs" library.
    ///
    /// Corresponds to: `GET /v1/me/tracks`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A `Page` object containing `SavedTrack` items.
    public func currentUserSavedTracks(
        limit: Int = 20,
        offset: Int = 0,
        market: String? = nil
    ) async throws -> Page<SavedTrack> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = TracksEndpoint.currentUserSavedTracks(
            limit: clampedLimit,
            offset: offset,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SavedTrack>.self, url: url)
    }

    /// Save one or more tracks to the current user's "Liked Songs" library.
    ///
    /// Corresponds to: `PUT /v1/me/tracks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the tracks. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func saveTracks(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = TracksEndpoint.saveTracksForCurrentUser()
        let url = apiURL(path: endpoint.path)

        // Reuse the IDsBody struct (defined in SpotifyRequestBodies.swift)
        let body = IDsBody(ids: clampedIDs)
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized PUT request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
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

    /// Remove one or more tracks from the current user's "Liked Songs" library.
    ///
    /// Corresponds to: `DELETE /v1/me/tracks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the tracks. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func removeTracks(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = TracksEndpoint.removeTracksForCurrentUser()
        let url = apiURL(path: endpoint.path)

        // Reuse the IDsBody struct
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

    /// Check if one or more tracks are already saved in the current
    /// user's "Liked Songs" library.
    ///
    /// Corresponds to: `GET /v1/me/tracks/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the tracks. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func checkSavedTracks(ids: [String]) async throws -> [Bool] {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else {
            return []  // Return an empty array if no IDs are provided
        }

        let endpoint = TracksEndpoint.checkCurrentUserSavedTracks(
            ids: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

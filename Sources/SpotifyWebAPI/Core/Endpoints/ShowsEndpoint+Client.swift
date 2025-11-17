import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single show.
    ///
    /// Corresponds to: `GET /v1/shows/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Show` object.
    public func show(
        id: String,
        market: String? = nil
    ) async throws -> Show {

        let endpoint = ShowsEndpoint.show(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Show.self, url: url)
    }

    /// Get Spotify catalog information for several shows based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/shows`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the shows. Maximum 50 IDs.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `SimplifiedShow` objects.
    public func shows(
        ids: [String],
        market: String? = nil
    ) async throws -> [SimplifiedShow] {

        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = ShowsEndpoint.severalShows(
            ids: clampedIDs,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralShowsResponse.self,
            url: url
        )

        // Return the unwrapped array
        return response.shows
    }

    /// Get Spotify catalog information about a show's episodes.
    ///
    /// Corresponds to: `GET /v1/shows/{id}/episodes`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the show.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedEpisode` items.
    public func showEpisodes(
        id: String,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedEpisode> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = ShowsEndpoint.showEpisodes(
            id: id,
            market: market,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SimplifiedEpisode>.self, url: url)
    }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get a list of shows saved in the current Spotify user's library.
    ///
    /// Corresponds to: `GET /v1/me/shows`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A `Page` object containing `SavedShow` items.
    public func currentUserSavedShows(
        limit: Int = 20,
        offset: Int = 0,
        market: String? = nil
    ) async throws -> Page<SavedShow> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = ShowsEndpoint.currentUserSavedShows(
            limit: clampedLimit,
            offset: offset,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SavedShow>.self, url: url)
    }

    /// Save one or more shows to the current user's library.
    ///
    /// Corresponds to: `PUT /v1/me/shows`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the shows. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func saveShows(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = ShowsEndpoint.saveShowsForCurrentUser()
        let url = apiURL(path: endpoint.path)

        // Reuse the IDsBody struct
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

    /// Remove one or more shows from the current user's library.
    ///
    /// Corresponds to: `DELETE /v1/me/shows`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the shows. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func removeShows(ids: [String]) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = ShowsEndpoint.removeShowsForCurrentUser()
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

    /// Check if one or more shows are already saved in the current
    /// user's library.
    ///
    /// Corresponds to: `GET /v1/me/shows/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the shows. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func checkSavedShows(ids: [String]) async throws -> [Bool] {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else {
            return []  // Return an empty array if no IDs are provided
        }

        let endpoint = ShowsEndpoint.checkCurrentUserSavedShows(ids: clampedIDs)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

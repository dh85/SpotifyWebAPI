import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single episode.
    ///
    /// Corresponds to: `GET /v1/episodes/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the episode.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Episode` object.
    public func episode(
        id: String,
        market: String? = nil
    ) async throws -> Episode {

        let endpoint = EpisodesEndpoint.episode(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Episode.self, url: url)
    }

    /// Get Spotify catalog information for several episodes based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/episodes`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the episodes. Maximum 50 IDs.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full `Episode` objects.
    public func episodes(
        ids: [String],
        market: String? = nil
    ) async throws -> [Episode] {

        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = EpisodesEndpoint.severalEpisodes(
            ids: clampedIDs,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralEpisodesResponse.self,
            url: url
        )

        // Return the unwrapped array
        return response.episodes
    }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get a list of the episodes saved in the current Spotify user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/episodes`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SavedEpisode` items.
    public func currentUserSavedEpisodes(
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SavedEpisode> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = EpisodesEndpoint.currentUserSavedEpisodes(
            market: market,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SavedEpisode>.self, url: url)
    }

    /// Save one or more episodes to the current user's "Your Music" library.
    ///
    /// Corresponds to: `PUT /v1/me/episodes`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the episodes. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func saveEpisodes(ids: [String]) async throws {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = EpisodesEndpoint.saveEpisodesForCurrentUser()
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

    /// Remove one or more episodes from the current user's "Your Music" library.
    ///
    /// Corresponds to: `DELETE /v1/me/episodes`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the episodes. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func removeEpisodes(ids: [String]) async throws {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = EpisodesEndpoint.removeEpisodesForCurrentUser()
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

    /// Check if one or more episodes are already saved in the current
    /// user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/episodes/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the episodes. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func checkSavedEpisodes(ids: [String]) async throws -> [Bool] {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else {
            return []  // Return an empty array if no IDs are provided
        }

        let endpoint = EpisodesEndpoint.checkCurrentUserSavedEpisodes(
            ids: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

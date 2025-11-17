import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single audiobook.
    ///
    /// Corresponds to: `GET /v1/audiobooks/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the audiobook.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Audiobook` object.
    public func audiobook(
        id: String,
        market: String? = nil
    ) async throws -> Audiobook {

        let endpoint = AudiobooksEndpoint.audiobook(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Audiobook.self, url: url)
    }

    /// Get Spotify catalog information for several audiobooks based on their
    /// Spotify IDs.
    ///
    /// Corresponds to: `GET /v1/audiobooks`
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the audiobooks. Maximum 50 IDs.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full `Audiobook` objects.
    public func audiobooks(
        ids: [String],
        market: String? = nil
    ) async throws -> [Audiobook] {

        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = AudiobooksEndpoint.severalAudiobooks(
            ids: clampedIDs,
            market: market
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralAudiobooksResponse.self,
            url: url
        )

        // Return the unwrapped array
        return response.audiobooks
    }

    /// Get Spotify catalog information about an audiobook's chapters.
    ///
    /// Corresponds to: `GET /v1/audiobooks/{id}/chapters`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the audiobook.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedChapter` items.
    public func audiobookChapters(
        id: String,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedChapter> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = AudiobooksEndpoint.audiobookChapters(
            id: id,
            market: market,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // We can reuse the existing Page<T> and SimplifiedChapter models
        return try await requestJSON(Page<SimplifiedChapter>.self, url: url)
    }

    /// GET /v1/chapters/{id}
    static func chapter(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/chapters/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// Get Spotify catalog information for a single chapter.
    ///
    /// Corresponds to: `GET /v1/chapters/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the chapter.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Chapter` object.
    public func chapter(
        id: String,
        market: String? = nil
    ) async throws -> Chapter {

        let endpoint = AudiobooksEndpoint.chapter(id: id, market: market)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Chapter.self, url: url)
    }

    /// Get Spotify catalog information for several chapters based on their
        /// Spotify IDs.
        ///
        /// Corresponds to: `GET /v1/chapters`
        ///
        /// - Parameters:
        ///   - ids: A list of the Spotify IDs for the chapters. Maximum 50 IDs.
        ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
        /// - Returns: A list of full `Chapter` objects.
        public func chapters(
            ids: [String],
            market: String? = nil
        ) async throws -> [Chapter] {

            // Clamp to Spotify's API limit
            let clampedIDs = Array(ids.prefix(50))
            guard !clampedIDs.isEmpty else { return [] }

            let endpoint = AudiobooksEndpoint.severalChapters(
                ids: clampedIDs,
                market: market
            )
            let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

            // Decode the wrapper object
            let response = try await requestJSON(
                SeveralChaptersResponse.self,
                url: url
            )

            // Return the unwrapped array
            return response.chapters
        }
}

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get a list of the audiobooks saved in the current Spotify user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/audiobooks`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SavedAudiobook` items.
    public func currentUserSavedAudiobooks(
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SavedAudiobook> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = AudiobooksEndpoint.currentUserSavedAudiobooks(
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<SavedAudiobook>.self, url: url)
    }

    /// Save one or more audiobooks to the current user's "Your Music" library.
    ///
    /// Corresponds to: `PUT /v1/me/audiobooks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the audiobooks. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func saveAudiobooks(ids: [String]) async throws {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = AudiobooksEndpoint.saveAudiobooksForCurrentUser()
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

    /// Remove one or more audiobooks from the current user's "Your Music" library.
    ///
    /// Corresponds to: `DELETE /v1/me/audiobooks`
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the audiobooks. Maximum 50 IDs.
    /// - Throws: An error if the request fails (e.g., non-200 response).
    public func removeAudiobooks(ids: [String]) async throws {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }  // Do nothing if list is empty

        let endpoint = AudiobooksEndpoint.removeAudiobooksForCurrentUser()
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

    /// Check if one or more audiobooks are already saved in the current
    /// user's "Your Music" library.
    ///
    /// Corresponds to: `GET /v1/me/audiobooks/contains`
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the audiobooks. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func checkSavedAudiobooks(ids: [String]) async throws -> [Bool] {
        // Clamp to Spotify's API limit
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else {
            return []  // Return an empty array if no IDs are provided
        }

        let endpoint = AudiobooksEndpoint.checkCurrentUserSavedAudiobooks(
            ids: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

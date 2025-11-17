import Foundation

extension SpotifyClient where Capability == UserAuthCapability {

    // MARK: - Async streams for playlists

    /// Streams the current user's playlists as an `AsyncThrowingStream`, transparently
    /// handling pagination and token refresh.
    ///
    /// - Parameters:
    ///   - pageSize: Number of playlists to request per page (1...50).
    ///   - maxItems: Optional cap on total emitted playlists.
    public nonisolated func currentUserPlaylistsStream(
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<SimplifiedPlaylist, Error> {
        let client = self  // capture the actor reference

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let clampedPageSize = min(max(pageSize, 1), 50)
                    var offset = 0
                    var emitted = 0

                    while true {
                        if Task.isCancelled { break }

                        let page = try await client.currentUserPlaylists(
                            limit: clampedPageSize,
                            offset: offset
                        )

                        for playlist in page.items {
                            if Task.isCancelled { break }

                            if let maxItems, emitted >= maxItems {
                                continuation.finish()
                                return
                            }

                            continuation.yield(playlist)
                            emitted += 1
                        }

                        if page.next == nil || emitted >= page.total {
                            break
                        }

                        offset += page.limit
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Streams playlists for a specific user as an `AsyncThrowingStream`.
    ///
    /// - Parameters:
    ///   - userID: Spotify user ID.
    ///   - pageSize: Number of playlists to request per page (1...50).
    ///   - maxItems: Optional cap on total emitted playlists.
    public nonisolated func userPlaylistsStream(
        userID: String,
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<SimplifiedPlaylist, Error> {
        let client = self  // capture the actor reference

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let clampedPageSize = min(max(pageSize, 1), 50)
                    var offset = 0
                    var emitted = 0

                    while true {
                        if Task.isCancelled { break }

                        let page = try await client.userPlaylists(
                            userID: userID,
                            limit: clampedPageSize,
                            offset: offset
                        )

                        for playlist in page.items {
                            if Task.isCancelled { break }

                            if let maxItems, emitted >= maxItems {
                                continuation.finish()
                                return
                            }

                            continuation.yield(playlist)
                            emitted += 1
                        }

                        if page.next == nil || emitted >= page.total {
                            break
                        }

                        offset += page.limit
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Change a playlist's details.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}`
    /// Requires either `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - name: Optional. The new name for the playlist.
    ///   - isPublic: Optional. `true` for public, `false` for private.
    ///   - collaborative: Optional. `true` to make collaborative (public must be false).
    ///   - description: Optional. The new description.
    public func changePlaylistDetails(
        id: String,
        name: String? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) async throws {

        // Don't send a request if there's nothing to change
        guard
            name != nil || isPublic != nil || collaborative != nil
                || description != nil
        else {
            return
        }

        let endpoint = PlaylistsEndpoint.changePlaylistDetails(id: id)
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = ChangePlaylistDetailsBody(
            name: name,
            isPublic: isPublic,
            collaborative: collaborative,
            description: description
        )
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

    /// Replace all items in a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks` (with `uris` query)
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to set.
    /// - Throws: An error if the request fails (e.g., non-201 response).
    public func replacePlaylistItems(
        id: String,
        uris: [String]
    ) async throws {

        // Note: Spotify allows sending an empty array to clear the playlist.
        let endpoint = PlaylistsEndpoint.replacePlaylistItems(
            id: id,
            uris: uris
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Make the authorized PUT request (no body)
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT"
        )

        // This action returns 201 Created on success
        guard response.statusCode == 201 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Reorder items in a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks` (with JSON body)
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - rangeStart: The 0-indexed position of the first item to move.
    ///   - insertBefore: The 0-indexed position to move the items to.
    ///   - rangeLength: Optional. The number of items to move. Defaults to 1.
    ///   - snapshotId: Optional. The playlist's snapshot ID (for optimistic locking).
    /// - Returns: A new `snapshotId` for the playlist.
    public func reorderPlaylistItems(
        id: String,
        rangeStart: Int,
        insertBefore: Int,
        rangeLength: Int? = nil,
        snapshotId: String? = nil
    ) async throws -> String {

        let endpoint = PlaylistsEndpoint.reorderPlaylistItems(id: id)
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = ReorderPlaylistItemsBody(
            rangeStart: rangeStart,
            insertBefore: insertBefore,
            rangeLength: rangeLength,
            snapshotId: snapshotId
        )
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized PUT request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
            body: httpBody,
            contentType: "application/json"
        )

        // This action returns 200 OK on success
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // Decode the snapshot ID
        let snapshot = try decodeJSON(SnapshotResponse.self, from: data)
        return snapshot.snapshotId
    }

    /// Add one or more items to a user's playlist.
    ///
    /// Corresponds to: `POST /v1/playlists/{id}/tracks`
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to add.
    ///   - position: Optional. The 0-indexed position to insert the items.
    /// - Returns: A new `snapshotId` for the playlist.
    public func addItemsToPlaylist(
        id: String,
        uris: [String],
        position: Int? = nil
    ) async throws -> String {

        guard !uris.isEmpty else {
            // You might want to define this error in SpotifyClientError
            throw SpotifyClientError.unexpectedResponse
        }

        let endpoint = PlaylistsEndpoint.addItemsToPlaylist(id: id)
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = AddPlaylistItemsBody(uris: uris, position: position)
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized POST request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "POST",
            body: httpBody,
            contentType: "application/json"
        )

        // This action returns 201 Created on success
        guard response.statusCode == 201 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // Decode the snapshot ID
        let snapshot = try decodeJSON(SnapshotResponse.self, from: data)
        return snapshot.snapshotId
    }

    /// Internal helper to send the DELETE request for removing items.
    private func removeItems(
        id: String,
        body: RemovePlaylistItemsBody
    ) async throws -> String {

        let endpoint = PlaylistsEndpoint.removeItemsFromPlaylist(id: id)
        let url = apiURL(path: endpoint.path)

        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized DELETE request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "DELETE",
            body: httpBody,
            contentType: "application/json"
        )

        // This action returns 200 OK on success
        guard (200..<300).contains(response.statusCode) else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // Decode the snapshot ID
        let snapshot = try decodeJSON(SnapshotResponse.self, from: data)
        return snapshot.snapshotId
    }

    /// Remove one or more items from a playlist by their URIs.
    ///
    /// Corresponds to: `DELETE /v1/playlists/{id}/tracks`
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to remove.
    ///   - snapshotId: Optional. The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    public func removePlaylistItems(
        id: String,
        byURIs uris: [String],
        snapshotId: String? = nil
    ) async throws -> String {

        guard !uris.isEmpty else {
            throw SpotifyClientError.unexpectedResponse  // Or a more specific error
        }

        let body = RemovePlaylistItemsBody.byURIs(
            uris,
            snapshotId: snapshotId
        )
        return try await removeItems(id: id, body: body)
    }

    /// Remove one or more items from a playlist by their 0-indexed positions.
    ///
    /// Corresponds to: `DELETE /v1/playlists/{id}/tracks`
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - positions: A list of 0-indexed positions to remove.
    ///   - snapshotId: Optional. The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    public func removePlaylistItems(
        id: String,
        byPositions positions: [Int],
        snapshotId: String? = nil
    ) async throws -> String {

        guard !positions.isEmpty else {
            throw SpotifyClientError.unexpectedResponse  // Or a more specific error
        }

        let body = RemovePlaylistItemsBody.byPositions(
            positions,
            snapshotId: snapshotId
        )
        return try await removeItems(id: id, body: body)
    }

    /// Get a list of the playlists owned or followed by the current user.
    ///
    /// Corresponds to: `GET /v1/me/playlists`
    /// Requires the `playlist-read-private` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedPlaylist` items.
    public func currentUserPlaylists(
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedPlaylist> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = PlaylistsEndpoint.currentUserPlaylists(
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // SimplifiedPlaylist and Page were defined in your initial code
        return try await requestJSON(Page<SimplifiedPlaylist>.self, url: url)
    }

    public func allCurrentUserPlaylists(
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) async throws -> [SimplifiedPlaylist] {
        try await collectAllPages(pageSize: pageSize, maxItems: maxItems) {
            limit,
            offset in
            try await currentUserPlaylists(limit: limit, offset: offset)
        }
    }

    /// Create a new playlist for a Spotify user.
    ///
    /// Corresponds to: `POST /v1/users/{user_id}/playlists`
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID to create the playlist for.
    ///   - name: The name for the new playlist.
    ///   - isPublic: Optional. `true` for public, `false` for private.
    ///   - collaborative: Optional. `true` to make collaborative.
    ///   - description: Optional. The new description.
    /// - Returns: The newly created `Playlist` object.
    public func createPlaylist(
        userID: String,
        name: String,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) async throws -> Playlist {

        let endpoint = PlaylistsEndpoint.createPlaylist(userID: userID)
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = CreatePlaylistBody(
            name: name,
            isPublic: isPublic,
            collaborative: collaborative,
            description: description
        )
        let httpBody = try JSONEncoder().encode(body)

        // Make the authorized POST request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "POST",
            body: httpBody,
            contentType: "application/json"
        )

        // This action returns 201 Created on success
        guard response.statusCode == 201 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }

        // Decode and return the new Playlist object
        return try decodeJSON(Playlist.self, from: data)
    }

    /// Upload a custom cover image for a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/images`
    /// Requires `ugc-image-upload` and `playlist-modify-public`
    /// or `playlist-modify-private` scopes.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - jpegData: The raw image data (must be a JPEG).
    public func addCustomPlaylistImage(
        id: String,
        jpegData: Data
    ) async throws {

        let endpoint = PlaylistsEndpoint.addCustomPlaylistImage(id: id)
        let url = apiURL(path: endpoint.path)

        // The API requires the raw JPEG data to be Base64-encoded
        // and sent as the request body.
        let httpBody = jpegData.base64EncodedData()

        // Make the authorized PUT request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "PUT",
            body: httpBody,
            contentType: "image/jpeg"  // This Content-Type is required
        )

        // A 202 Accepted response means success.
        guard response.statusCode == 202 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }
}

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get a playlist owned by a Spotify user.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - fields: Optional. A comma-separated list of fields to filter.
    ///   - additionalTypes: Optional. A list of types to include
    ///     (e.g., "track", "episode").
    /// - Returns: A full `Playlist` object.
    public func playlist(
        id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> Playlist {

        let endpoint = PlaylistsEndpoint.playlist(
            id: id,
            market: market,
            fields: fields,
            additionalTypes: additionalTypes
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The 'Playlist' model was defined in your initial code
        return try await requestJSON(Playlist.self, url: url)
    }

    /// Get the tracks or episodes in a playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}/tracks`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - fields: Optional. A comma-separated list of fields to filter.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - additionalTypes: Optional. A list of types to include
    ///     (e.g., "track", "episode").
    /// - Returns: A `Page` object containing `PlaylistTrackItem` items.
    public func playlistItems(
        id: String,
        market: String? = nil,
        fields: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        additionalTypes: [String]? = nil
    ) async throws -> Page<PlaylistTrackItem> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = PlaylistsEndpoint.playlistItems(
            id: id,
            market: market,
            fields: fields,
            limit: clampedLimit,
            offset: offset,
            additionalTypes: additionalTypes
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<PlaylistTrackItem>.self, url: url)
    }

    /// Get a list of the playlists owned or followed by a specific user.
    ///
    /// Corresponds to: `GET /v1/users/{user_id}/playlists`
    /// Requires the `playlist-read-private` scope to see private playlists.
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `SimplifiedPlaylist` items.
    public func userPlaylists(
        userID: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedPlaylist> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = PlaylistsEndpoint.userPlaylists(
            userID: userID,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // SimplifiedPlaylist and Page were defined in your initial code
        return try await requestJSON(Page<SimplifiedPlaylist>.self, url: url)
    }

    public func allUserPlaylists(
        userID: String,
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) async throws -> [SimplifiedPlaylist] {
        try await collectAllPages(pageSize: pageSize, maxItems: maxItems) {
            limit,
            offset in
            try await userPlaylists(
                userID: userID,
                limit: limit,
                offset: offset
            )
        }
    }

    /// Get the cover image for a playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}/images`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    /// - Returns: A list of `SpotifyImage` objects.
    public func playlistCoverImage(
        id: String
    ) async throws -> [SpotifyImage] {

        let endpoint = PlaylistsEndpoint.playlistCoverImage(id: id)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // This endpoint returns an array of SpotifyImage objects directly
        return try await requestJSON([SpotifyImage].self, url: url)
    }
}

import Foundation

extension SpotifyClient where Capability == UserAuthCapability {

    /// Add the current user as a follower of a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/followers`
    /// Requires the `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - isPublic: Optional. If true, the playlist will be public.
    ///               If nil, the default (usually public) is used.
    public func followPlaylist(
        id: String,
        isPublic: Bool? = nil
    ) async throws {

        let endpoint = FollowEndpoint.followPlaylist(id: id)
        let url = apiURL(path: endpoint.path)

        // Prepare the JSON body
        let body = FollowPlaylistBody(isPublic: isPublic)
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

    /// Remove the current user as a follower of a playlist.
    ///
    /// Corresponds to: `DELETE /v1/playlists/{id}/followers`
    /// Requires the `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameter id: The Spotify ID for the playlist.
    public func unfollowPlaylist(id: String) async throws {

        let endpoint = FollowEndpoint.unfollowPlaylist(id: id)
        let url = apiURL(path: endpoint.path)

        // Make the authorized DELETE request
        let (data, response) = try await authorizedRequest(
            url: url,
            method: "DELETE"
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

    /// Get the current user's followed artists.
    ///
    /// Corresponds to: `GET /v1/me/following?type=artist`
    /// Requires the `user-follow-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: The last artist ID retrieved from the previous request.
    /// - Returns: A `CursorBasedPage` object containing `Artist` items.
    public func followedArtists(
        limit: Int = 20,
        after: String? = nil
    ) async throws -> CursorBasedPage<Artist> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = FollowEndpoint.getFollowedArtists(
            limit: clampedLimit,
            after: after
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper and return the inner page
        let response = try await requestJSON(
            FollowedArtistsResponse.self,
            url: url
        )

        return response.artists
    }

    /// Follow one or more artists.
    ///
    /// Corresponds to: `PUT /v1/me/following?type=artist`
    /// Requires the `user-follow-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the artists. Maximum 50 IDs.
    public func followArtists(_ ids: [String]) async throws {
        try await follow(ids: ids, type: .artist)
    }

    /// Follow one or more users.
    ///
    /// Corresponds to: `PUT /v1/me/following?type=user`
    /// Requires the `user-follow-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the users. Maximum 50 IDs.
    public func followUsers(_ ids: [String]) async throws {
        try await follow(ids: ids, type: .user)
    }

    /// Internal helper to execute the follow request.
    private func follow(ids: [String], type: FollowType) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }

        let endpoint = FollowEndpoint.follow(type: type)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

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

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Unfollow one or more artists.
    ///
    /// Corresponds to: `DELETE /v1/me/following?type=artist`
    /// Requires the `user-follow-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the artists. Maximum 50 IDs.
    public func unfollowArtists(_ ids: [String]) async throws {
        try await unfollow(ids: ids, type: .artist)
    }

    /// Unfollow one or more users.
    ///
    /// Corresponds to: `DELETE /v1/me/following?type=user`
    /// Requires the `user-follow-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the users. Maximum 50 IDs.
    public func unfollowUsers(_ ids: [String]) async throws {
        try await unfollow(ids: ids, type: .user)
    }

    /// Internal helper to execute the unfollow request.
    private func unfollow(ids: [String], type: FollowType) async throws {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return }

        let endpoint = FollowEndpoint.unfollow(type: type)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

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

        // A 204 No Content response means success.
        guard response.statusCode == 204 else {
            let bodyString =
                String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: bodyString
            )
        }
    }

    /// Check if the current user follows one or more artists.
    ///
    /// Corresponds to: `GET /v1/me/following/contains?type=artist`
    /// Requires the `user-follow-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the artists. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func isFollowingArtists(_ ids: [String]) async throws -> [Bool] {
        try await checkFollowing(ids: ids, type: .artist)
    }

    /// Check if the current user follows one or more users.
    ///
    /// Corresponds to: `GET /v1/me/following/contains?type=user`
    /// Requires the `user-follow-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the users. Maximum 50 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    public func isFollowingUsers(_ ids: [String]) async throws -> [Bool] {
        try await checkFollowing(ids: ids, type: .user)
    }

    /// Internal helper to execute the check request.
    private func checkFollowing(ids: [String], type: FollowType) async throws
        -> [Bool]
    {
        // Spotify's API limit is 50 IDs per request
        let clampedIDs = Array(ids.prefix(50))
        guard !clampedIDs.isEmpty else { return [] }

        let endpoint = FollowEndpoint.checkFollowing(
            type: type,
            ids: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Check to see if one or more Spotify users are following a specified playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}/followers/contains`
    ///
    /// - Parameters:
    ///   - playlistID: The Spotify ID of the playlist.
    ///   - userIDs: A list of Spotify User IDs to check. Maximum 5 IDs.
    /// - Returns: An array of booleans, in the same order as the IDs requested.
    ///   `true` if the user follows the playlist, `false` otherwise.
    public func areUsersFollowingPlaylist(
        playlistID: String,
        userIDs: [String]
    ) async throws -> [Bool] {

        // Spotify's API limit is 5 IDs per request for this specific endpoint
        let clampedIDs = Array(userIDs.prefix(5))
        guard !clampedIDs.isEmpty else {
            return []  // Return empty if no IDs provided
        }

        let endpoint = FollowEndpoint.checkUsersFollowPlaylist(
            playlistID: playlistID,
            userIDs: clampedIDs
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // The endpoint directly returns an array of booleans
        return try await requestJSON([Bool].self, url: url)
    }
}

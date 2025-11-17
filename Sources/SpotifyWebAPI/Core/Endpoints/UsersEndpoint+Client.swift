import Foundation

extension SpotifyClient where Capability == UserAuthCapability {

    /// Get detailed profile information about the current user.
    ///
    /// Corresponds to: `GET /v1/me`
    /// Requires the `user-read-private` scope to see subscription details (product)
    /// and country. Requires `user-read-email` to see the email address.
    ///
    /// - Returns: A `CurrentUserProfile` object.
    public func currentUserProfile() async throws -> CurrentUserProfile {

        let endpoint = UsersEndpoint.currentUserProfile()
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(CurrentUserProfile.self, url: url)
    }

    /// Get the current user's top artists based on calculated affinity.
    ///
    /// Corresponds to: `GET /v1/me/top/artists`
    /// Requires the `user-top-read` scope.
    ///
    /// - Parameters:
    ///   - timeRange: Over what time frame the affinities are computed. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `Artist` items.
    public func myTopArtists(
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Artist> {

        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = UsersEndpoint.topItems(
            type: "artists",
            timeRange: timeRange.rawValue,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<Artist>.self, url: url)
    }

    /// Get the current user's top tracks based on calculated affinity.
    ///
    /// Corresponds to: `GET /v1/me/top/tracks`
    /// Requires the `user-top-read` scope.
    ///
    /// - Parameters:
    ///   - timeRange: Over what time frame the affinities are computed. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `Track` items.
    public func myTopTracks(
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Track> {

        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = UsersEndpoint.topItems(
            type: "tracks",
            timeRange: timeRange.rawValue,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(Page<Track>.self, url: url)
    }
}

extension SpotifyClient where Capability: PublicSpotifyCapability {

    /// Get public profile information about a Spotify user.
    ///
    /// Corresponds to: `GET /v1/users/{user_id}`
    ///
    /// - Parameter id: The Spotify user ID.
    /// - Returns: A `PublicUserProfile` object.
    public func userProfile(id: String) async throws -> PublicUserProfile {

        let endpoint = UsersEndpoint.userProfile(id: id)
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        return try await requestJSON(PublicUserProfile.self, url: url)
    }
}

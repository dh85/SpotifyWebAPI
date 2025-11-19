import Foundation

private struct FollowedArtistsWrapper: Decodable {
    let artists: CursorBasedPage<Artist>
}

/// A service providing access to Spotify user profiles, following status, and affinity data (Top Artists/Tracks).
public struct UsersService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access (Get any user)
extension UsersService where Capability: PublicSpotifyCapability {

    /// Get public profile information for a specified user.
    ///
    /// Corresponds to: `GET /v1/users/{user_id}`.
    ///
    /// - Parameter id: The Spotify ID of the target user.
    /// - Returns: A ``PublicUserProfile`` object.
    public func get(_ id: String) async throws -> PublicUserProfile {
        let request = SpotifyRequest<PublicUserProfile>.get("/users/\(id)")
        return try await client.perform(request)
    }

    /// Check to see if one or more Spotify users are following a specified playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{playlist_id}/followers/contains`.
    ///
    /// - Parameters:
    ///   - playlistID: The Spotify ID of the target playlist.
    ///   - userIDs: A list of Spotify User IDs to check (max 5).
    /// - Returns: An array of booleans indicating follow status.
    public func checkFollowing(
        playlist playlistID: String,
        users userIDs: Set<String>
    ) async throws -> [Bool] {
        let sortedUserIDs = userIDs.sorted()
        let query: [URLQueryItem] = [
            .init(name: "ids", value: sortedUserIDs.joined(separator: ","))
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/playlists/\(playlistID)/followers/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

// MARK: - Private Access (Current User operations)
extension UsersService where Capability == UserAuthCapability {

    /// Get detailed profile information about the current user.
    ///
    /// Corresponds to: `GET /v1/me`.
    /// Requires `user-read-private` and `user-read-email` scopes.
    ///
    /// - Returns: A ``CurrentUserProfile`` object.
    public func me() async throws -> CurrentUserProfile {
        let request = SpotifyRequest<CurrentUserProfile>.get("/me")
        return try await client.perform(request)
    }

    /// Get the current user's top artists based on calculated affinity.
    ///
    /// Corresponds to: `GET /v1/me/top/artists`.
    /// Requires the `user-top-read` scope.
    ///
    /// - Parameters:
    ///   - range: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``Artist`` items.
    public func topArtists(
        range: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Artist> {

        let clampedLimit = min(max(limit, 1), 50)

        let query: [URLQueryItem] = [
            .init(name: "type", value: "artists"),
            .init(name: "time_range", value: range.rawValue),
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]

        let request = SpotifyRequest<Page<Artist>>.get(
            "/me/top/artists",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get the current user's top tracks based on calculated affinity.
    ///
    /// Corresponds to: `GET /v1/me/top/tracks`.
    /// Requires the `user-top-read` scope.
    ///
    /// - Parameters:
    ///   - range: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``Track`` items.
    public func topTracks(
        range: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Track> {

        let clampedLimit = min(max(limit, 1), 50)

        let query: [URLQueryItem] = [
            .init(name: "type", value: "tracks"),
            .init(name: "time_range", value: range.rawValue),
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]

        let request = SpotifyRequest<Page<Track>>.get(
            "/me/top/tracks",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get the current user's followed artists.
    ///
    /// Corresponds to: `GET /v1/me/following?type=artist`.
    /// Requires the `user-follow-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: The last artist ID retrieved for cursor-based paging.
    /// - Returns: A cursor-based page of ``Artist`` items.
    public func followedArtists(
        limit: Int = 20,
        after: String? = nil
    ) async throws -> CursorBasedPage<Artist> {

        let clampedLimit = min(max(limit, 1), 50)

        var query: [URLQueryItem] = [
            .init(name: "type", value: "artist"),
            .init(name: "limit", value: String(clampedLimit)),
        ]
        if let after {
            query.append(.init(name: "after", value: after))
        }

        let request = SpotifyRequest<FollowedArtistsWrapper>.get(
            "/me/following",
            query: query
        )
        return try await client.perform(request).artists
    }

    // MARK: - Following Modifiers

    /// Follow one or more artists.
    /// Requires the `user-follow-modify` scope.
    public func follow(artists ids: Set<String>) async throws {
        try await follow(ids: ids, type: .artist)
    }

    /// Follow one or more users.
    /// Requires the `user-follow-modify` scope.
    public func follow(users ids: Set<String>) async throws {
        try await follow(ids: ids, type: .user)
    }

    /// Unfollow one or more artists.
    /// Requires the `user-follow-modify` scope.
    public func unfollow(artists ids: Set<String>) async throws {
        try await unfollow(ids: ids, type: .artist)
    }

    /// Unfollow one or more users.
    /// Requires the `user-follow-modify` scope.
    public func unfollow(users ids: Set<String>) async throws {
        try await unfollow(ids: ids, type: .user)
    }

    /// Check if the current user follows one or more artists.
    /// Requires the `user-follow-read` scope.
    public func checkFollowing(artists ids: Set<String>) async throws -> [Bool] {
        try await check(ids: ids, type: .artist)
    }

    /// Check if the current user follows one or more users.
    /// Requires the `user-follow-read` scope.
    public func checkFollowing(users ids: Set<String>) async throws -> [Bool] {
        try await check(ids: ids, type: .user)
    }

    // MARK: - Private Helpers

    private func follow(ids: Set<String>, type: FollowType) async throws {
        let query: [URLQueryItem] = [.init(name: "type", value: type.rawValue)]
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/following",
            query: query,
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    private func unfollow(ids: Set<String>, type: FollowType) async throws {
        let query: [URLQueryItem] = [.init(name: "type", value: type.rawValue)]
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/following",
            query: query,
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    private func check(ids: Set<String>, type: FollowType) async throws -> [Bool] {
        let sortedIDs = ids.sorted()
        let query: [URLQueryItem] = [
            .init(name: "type", value: type.rawValue),
            .init(name: "ids", value: sortedIDs.joined(separator: ",")),
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/following/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

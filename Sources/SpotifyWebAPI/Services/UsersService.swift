import Foundation

private struct FollowedArtistsWrapper: Decodable {
    let artists: CursorBasedPage<Artist>
}

private enum FollowType: String {
    case artist
    case user
}

/// A service for accessing Spotify user profiles, following status, and affinity data.
///
/// ## Overview
///
/// UsersService provides access to:
/// - User profile information
/// - Top artists and tracks (listening affinity)
/// - Following/unfollowing artists and users
/// - Followed artists
///
/// ## Examples
///
/// ### Get Current User Profile
/// ```swift
/// let profile = try await client.users.me()
/// print("User: \(profile.displayName ?? "Unknown")")
/// print("Email: \(profile.email ?? "N/A")")
/// print("Country: \(profile.country ?? "N/A")")
/// print("Followers: \(profile.followers.total)")
/// ```
///
/// ### Get Top Artists and Tracks
/// ```swift
/// // Get top artists from the last 6 months
/// let topArtists = try await client.users.topArtists(
///     range: .mediumTerm,
///     limit: 20
/// )
/// print("Your top artists:")
/// for (index, artist) in topArtists.items.enumerated() {
///     print("\(index + 1). \(artist.name)")
/// }
///
/// // Get top tracks from all time
/// let topTracks = try await client.users.topTracks(
///     range: .longTerm,
///     limit: 50
/// )
/// for track in topTracks.items {
///     print("\(track.name) by \(track.artistNames)")
/// }
/// ```
///
/// ### Follow Artists
/// ```swift
/// // Follow artists
/// let artistIDs: Set<String> = ["artist1", "artist2", "artist3"]
/// try await client.users.follow(artists: artistIDs)
///
/// // Check if following
/// let following = try await client.users.checkFollowing(artists: artistIDs)
/// for (id, isFollowing) in zip(artistIDs, following) {
///     print("\(id): \(isFollowing ? "Following" : "Not following")")
/// }
///
/// // Unfollow artists
/// try await client.users.unfollow(artists: artistIDs)
/// ```
///
/// ### Get Followed Artists
/// ```swift
/// var allFollowedArtists: [Artist] = []
/// var page = try await client.users.followedArtists(limit: 50)
///
/// allFollowedArtists.append(contentsOf: page.items)
///
/// // Paginate through all followed artists
/// while let cursor = page.cursors?.after {
///     page = try await client.users.followedArtists(limit: 50, after: cursor)
///     allFollowedArtists.append(contentsOf: page.items)
/// }
///
/// print("You follow \(allFollowedArtists.count) artists")
/// ```
///
/// ### Get Public User Profile
/// ```swift
/// let publicProfile = try await client.users.get("spotify")
/// print("\(publicProfile.displayName ?? "Unknown") has \(publicProfile.followers.total) followers")
/// ```
///
/// ## Time Ranges
///
/// When fetching top artists/tracks, you can specify:
/// - `.shortTerm` - Last 4 weeks
/// - `.mediumTerm` - Last 6 months (default)
/// - `.longTerm` - All time
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile)
public struct UsersService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }

    private func validateUserIDs(_ ids: Set<String>) throws {
        try validateMaxIdCount(50, for: ids)
    }

    private func validatePlaylistFollowUserIDs(_ ids: Set<String>) throws {
        guard ids.count <= 5 else {
            throw SpotifyClientError.invalidRequest(
                reason: "Maximum of 5 user IDs allowed. You provided \(ids.count)."
            )
        }
    }
}

// MARK: - Public Access
extension UsersService where Capability: PublicSpotifyCapability {

    /// Get public profile information for a specified user.
    ///
    /// - Parameter id: The Spotify ID for the user.
    /// - Returns: A `PublicUserProfile` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-profile)
    public func get(_ id: String) async throws -> PublicUserProfile {
        let request = SpotifyRequest<PublicUserProfile>.get("/users/\(id)")
        return try await client.perform(request)
    }

    /// Check if one or more users are following a specified playlist.
    ///
    /// - Parameters:
    ///   - playlistID: The Spotify ID for the playlist.
    ///   - userIDs: A list of Spotify User IDs (max 5).
    /// - Returns: An array of booleans indicating follow status.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-if-user-follows-playlist)
    public func checkFollowing(
        playlist playlistID: String,
        users userIDs: Set<String>
    ) async throws -> [Bool] {
        try validatePlaylistFollowUserIDs(userIDs)
        let query = [URLQueryItem(name: "ids", value: userIDs.sorted().joined(separator: ","))]
        let request = SpotifyRequest<[Bool]>.get(
            "/playlists/\(playlistID)/followers/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

// MARK: - User Access
extension UsersService where Capability == UserAuthCapability {

    /// Get detailed profile information about the current user.
    ///
    /// - Returns: A `CurrentUserProfile` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile)
    public func me() async throws -> CurrentUserProfile {
        let request = SpotifyRequest<CurrentUserProfile>.get("/me")
        return try await client.perform(request)
    }

    /// Get the current user's top artists based on calculated affinity.
    ///
    /// - Parameters:
    ///   - range: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `Artist` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-top-artists-and-tracks)
    public func topArtists(
        range: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Artist> {
        try validateLimit(limit)
        let query =
            [
                URLQueryItem(name: "time_range", value: range.rawValue)
            ] + makePaginationQuery(limit: limit, offset: offset)
        let request = SpotifyRequest<Page<Artist>>.get("/me/top/artists", query: query)
        return try await client.perform(request)
    }

    /// Get the current user's top tracks based on calculated affinity.
    ///
    /// - Parameters:
    ///   - range: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of `Track` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-top-artists-and-tracks)
    public func topTracks(
        range: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Track> {
        try validateLimit(limit)
        let query =
            [
                URLQueryItem(name: "time_range", value: range.rawValue)
            ] + makePaginationQuery(limit: limit, offset: offset)
        let request = SpotifyRequest<Page<Track>>.get("/me/top/tracks", query: query)
        return try await client.perform(request)
    }

    /// Get the current user's followed artists.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: The last artist ID retrieved for cursor-based paging.
    /// - Returns: A cursor-based page of `Artist` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-followed)
    public func followedArtists(
        limit: Int = 20,
        after: String? = nil
    ) async throws -> CursorBasedPage<Artist> {
        try validateLimit(limit)
        var query = [
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let after {
            query.append(URLQueryItem(name: "after", value: after))
        }
        let request = SpotifyRequest<FollowedArtistsWrapper>.get("/me/following", query: query)
        return try await client.perform(request).artists
    }

    /// Follow one or more artists.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/follow-artists-users)
    public func follow(artists ids: Set<String>) async throws {
        try await follow(ids: ids, type: .artist)
    }

    /// Follow one or more users.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/follow-artists-users)
    public func follow(users ids: Set<String>) async throws {
        try await follow(ids: ids, type: .user)
    }

    /// Unfollow one or more artists.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users)
    public func unfollow(artists ids: Set<String>) async throws {
        try await unfollow(ids: ids, type: .artist)
    }

    /// Unfollow one or more users.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/unfollow-artists-users)
    public func unfollow(users ids: Set<String>) async throws {
        try await unfollow(ids: ids, type: .user)
    }

    /// Check if the current user follows one or more artists.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-current-user-follows)
    public func checkFollowing(artists ids: Set<String>) async throws -> [Bool] {
        return try await check(ids: ids, type: .artist)
    }

    /// Check if the current user follows one or more users.
    ///
    /// - Parameter ids: A list of Spotify IDs (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/check-current-user-follows)
    public func checkFollowing(users ids: Set<String>) async throws -> [Bool] {
        return try await check(ids: ids, type: .user)
    }

    // MARK: - Private Helpers

    private func follow(ids: Set<String>, type: FollowType) async throws {
        try validateUserIDs(ids)
        let query = [URLQueryItem(name: "type", value: type.rawValue)]
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/following",
            query: query,
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    private func unfollow(ids: Set<String>, type: FollowType) async throws {
        try validateUserIDs(ids)
        let query = [URLQueryItem(name: "type", value: type.rawValue)]
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/following",
            query: query,
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    private func check(ids: Set<String>, type: FollowType) async throws -> [Bool] {
        try validateUserIDs(ids)
        let query = [
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "ids", value: ids.sorted().joined(separator: ",")),
        ]
        let request = SpotifyRequest<[Bool]>.get("/me/following/contains", query: query)
        return try await client.perform(request)
    }
}

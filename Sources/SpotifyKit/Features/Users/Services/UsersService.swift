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
///     timeRange: .mediumTerm,
///     limit: 20
/// )
/// print("Your top artists:")
/// for (index, artist) in topArtists.items.enumerated() {
///     print("\(index + 1). \(artist.name)")
/// }
///
/// // Get top tracks from all time
/// let topTracks = try await client.users.topTracks(
///     timeRange: .longTerm,
///     limit: 50
/// )
/// for track in topTracks.items {
///     print("\(track.name) by \(track.artistNames ?? "")")
/// }
///
/// // Stream all top tracks efficiently
/// for try await track in client.users.streamTopTracks(timeRange: .shortTerm) {
///     print("\(track.name) - \(track.durationFormatted ?? "")")
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
/// When fetching top artists/tracks, specify the `timeRange` parameter:
/// - `.shortTerm` - Last 4 weeks of listening history
/// - `.mediumTerm` - Last 6 months (default)
/// - `.longTerm` - Several years of listening data
///
/// The `timeRange` parameter name makes it clear you're filtering by temporal data,
/// improving API clarity over the generic "range" term.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile)
///
/// ## Combine Counterparts
///
/// Publisher helpers such as ``UsersService/mePublisher(priority:)`` and
/// ``UsersService/topArtistsPublisher(range:limit:offset:priority:)`` are declared in
/// `UsersService+Combine.swift`. They call back into these async implementations so both
/// concurrency models share behavior.
public struct UsersService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

extension UsersService: ServiceIDValidating {
    static var maxBatchSize: Int { SpotifyAPILimits.Users.followBatchSize }

    private func validateUserIDs(_ ids: Set<String>) throws {
        try validateIDs(ids)
    }

    private func validatePlaylistFollowUserIDs(_ ids: Set<String>) throws {
        let maximum = SpotifyAPILimits.Users.playlistFollowerCheckBatchSize
        guard ids.count <= maximum else {
            throw SpotifyClientError.invalidRequest(
                reason: "Maximum of \(maximum) user IDs allowed. You provided \(ids.count)."
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
        return
            try await client
            .get("/users/\(id)")
            .decode(PublicUserProfile.self)
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

        return
            try await client
            .get("/playlists/\(playlistID)/followers/contains")
            .query("ids", userIDs.sorted().joined(separator: ","))
            .decode([Bool].self)
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
        return
            try await client
            .get("/me")
            .decode(CurrentUserProfile.self)
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
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Artist> {
        try validateLimit(limit)
        return
            try await client
            .get("/me/top/artists")
            .query("time_range", timeRange.rawValue)
            .paginate(limit: limit, offset: offset)
            .decode(Page<Artist>.self)
    }

    /// Streams entire pages of the current user's top artists.
    ///
    /// - Parameters:
    ///   - timeRange: Time frame for affinity calculations.
    ///   - pageSize: Number of artists per request (clamped to 1...50). Default: 50.
    ///   - maxPages: Optional limit on the number of pages to emit.
    public func streamTopArtistPages(
        timeRange: TimeRange = .mediumTerm,
        pageSize: Int = 50,
        maxPages: Int? = nil
    ) -> AsyncThrowingStream<Page<Artist>, Error> {
        client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
            try await self.topArtists(timeRange: timeRange, limit: limit, offset: offset)
        }
    }

    /// Streams individual top artists for sequential use (e.g., playlist generation, analytics).
    public func streamTopArtists(
        timeRange: TimeRange = .mediumTerm,
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<Artist, Error> {
        client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
            try await self.topArtists(timeRange: timeRange, limit: limit, offset: offset)
        }
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
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Track> {
        try validateLimit(limit)
        return
            try await client
            .get("/me/top/tracks")
            .query("time_range", timeRange.rawValue)
            .paginate(limit: limit, offset: offset)
            .decode(Page<Track>.self)
    }

    /// Streams entire pages of the current user's top tracks for chunked analytics.
    ///
    /// - Parameters:
    ///   - timeRange: Time frame for affinity calculations.
    ///   - pageSize: Desired number of tracks per request (clamped to 1...50). Default: 50.
    ///   - maxPages: Optional cap on total pages emitted.
    public func streamTopTrackPages(
        timeRange: TimeRange = .mediumTerm,
        pageSize: Int = 50,
        maxPages: Int? = nil
    ) -> AsyncThrowingStream<Page<Track>, Error> {
        client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
            try await self.topTracks(timeRange: timeRange, limit: limit, offset: offset)
        }
    }

    /// Streams individual top tracks for sequential analytics.
    public func streamTopTracks(
        timeRange: TimeRange = .mediumTerm,
        pageSize: Int = 50,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<Track, Error> {
        client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
            try await self.topTracks(timeRange: timeRange, limit: limit, offset: offset)
        }
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
        var builder =
            client
            .get("/me/following")
            .query("type", "artist")
            .query("limit", limit)

        if let after {
            builder = builder.query("after", after)
        }

        let wrapper = try await builder.decode(FollowedArtistsWrapper.self)
        return wrapper.artists
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
        try await client
            .put("/me/following")
            .query("type", type.rawValue)
            .body(IDsBody(ids: ids))
            .execute()
    }

    private func unfollow(ids: Set<String>, type: FollowType) async throws {
        try validateUserIDs(ids)
        try await client
            .delete("/me/following")
            .query("type", type.rawValue)
            .body(IDsBody(ids: ids))
            .execute()
    }

    private func check(ids: Set<String>, type: FollowType) async throws -> [Bool] {
        try validateUserIDs(ids)
        return
            try await client
            .get("/me/following/contains")
            .query("type", type.rawValue)
            .query("ids", ids.sorted().joined(separator: ","))
            .decode([Bool].self)
    }
}

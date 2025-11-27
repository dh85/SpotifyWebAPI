import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// A service for interacting with Spotify Playlists, managing items, and updating details.
///
/// ## Overview
///
/// PlaylistsService provides comprehensive playlist management including:
/// - Fetching playlist details and tracks
/// - Creating and modifying playlists
/// - Adding, removing, and reordering tracks
/// - Following and unfollowing playlists
/// - Managing playlist cover images
///
/// ## Examples
///
/// ### Get a Playlist
/// ```swift
/// let playlist = try await client.playlists.get("37i9dQZF1DXcBWIGoYBM5M")
/// print("\(playlist.name) has \(playlist.totalTracks) tracks")
/// ```
///
/// ### Create and Populate a Playlist
/// ```swift
/// // Create playlist
/// let playlist = try await client.playlists.create(
///     for: "user_id",
///     name: "My Awesome Playlist",
///     description: "Created with SpotifyKit",
///     isPublic: true
/// )
///
/// // Add tracks
/// let trackURIs = [
///     "spotify:track:6rqhFgbbKwnb9MLmUQDhG6",
///     "spotify:track:4cOdK2wGLETKBW3PvgPWqT"
/// ]
/// _ = try await client.playlists.add(to: playlist.id, uris: trackURIs)
/// ```
///
/// ### Stream All Tracks from a Large Playlist
/// ```swift
/// for try await item in client.playlists.streamItems("playlist_id") {
///     if let track = item.track as? Track {
///         print("\(track.name) by \(track.artistNames)")
///     }
/// }
/// ```
///
/// ### Batch Operations
/// ```swift
/// // Add many tracks (automatically chunked into batches of 100)
/// let manyTracks = Array(repeating: "spotify:track:...", count: 500)
/// try await client.playlists.addTracks(manyTracks, to: "playlist_id")
/// ```
///
/// - SeeAlso: ``PlaylistsServiceExtensions`` for batch operations
///
/// ## Combine Counterparts
///
/// All playlist operations have mirrored publishers in `PlaylistsService+Combine.swift`—for
/// example ``PlaylistsService/getPublisher(_:market:fields:additionalTypes:priority:)`` and
/// ``PlaylistsService/addPublisher(to:uris:position:priority:)``. Import Combine to call those
/// helpers without hunting for a different API surface.
public struct PlaylistsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>

    init(client: SpotifyClient<Capability>) {
        self.client = client
    }
}

// MARK: - Public Access
extension PlaylistsService where Capability: PublicSpotifyCapability {

    /// Get a playlist owned by a Spotify user.
    /// Corresponds to: `GET /v1/playlists/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - fields: A comma-separated list of fields to filter the response.
    ///   - additionalTypes: A set of item types to include (track, episode).
    /// - Returns: A full `Playlist` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlist)
    public func get(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil
    ) async throws -> Playlist {
        var builder = client.get("/playlists/\(id)")

        if let market {
            builder = builder.query("market", market)
        }
        if let fields {
            builder = builder.query("fields", fields)
        }
        if let additionalTypes {
            let value = additionalTypes.map { $0.rawValue }.sorted().joined(separator: ",")
            builder = builder.query("additional_types", value)
        }

        return try await builder.decode(Playlist.self)
    }

    /// Get the tracks or episodes in a playlist.
    /// Corresponds to: `GET /v1/playlists/{id}/tracks`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - fields: A comma-separated list of fields to filter the response.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - additionalTypes: A set of item types to include (track, episode).
    /// - Returns: A `Page` object containing `PlaylistTrackItem` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
    public func items(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        additionalTypes: Set<AdditionalItemType>? = nil
    ) async throws -> Page<PlaylistTrackItem> {
        try validateLimit(limit)
        var builder =
            client
            .get("/playlists/\(id)/tracks")
            .paginate(limit: limit, offset: offset)

        if let market {
            builder = builder.query("market", market)
        }
        if let fields {
            builder = builder.query("fields", fields)
        }
        if let additionalTypes {
            let value = additionalTypes.map { $0.rawValue }.sorted().joined(separator: ",")
            builder = builder.query("additional_types", value)
        }

        return try await builder.decode(Page<PlaylistTrackItem>.self)
    }

    /// Get all tracks or episodes in a playlist.
    ///
    /// Automatically fetches all pages.
    ///
    /// - Warning: Fetches up to 5,000 items by default. Use `maxItems: nil` to fetch all (may be slow for large playlists).
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - fields: A comma-separated list of fields to filter the response.
    ///   - additionalTypes: A set of item types to include (track, episode).
    ///   - maxItems: Limit on total items to fetch. Default: 5,000. Use `nil` for unlimited.
    /// - Returns: Array of all `PlaylistTrackItem` objects.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
    public func allItems(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil,
        maxItems: Int? = 5000
    ) async throws -> [PlaylistTrackItem] {
        try await playlistItemsProvider(
            id,
            market: market,
            fields: fields,
            additionalTypes: additionalTypes,
            defaultMaxItems: 5000
        ).all(maxItems: maxItems)
    }

    /// Stream tracks or episodes from a playlist.
    ///
    /// Returns an `AsyncStream` that yields items one at a time as pages are fetched.
    /// More memory efficient than `allItems` for large playlists.
    ///
    /// ## Example
    /// ```swift
    /// for try await item in client.playlists.streamItems("playlist_id") {
    ///     print("Track: \(item.track?.name ?? "Unknown")")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - fields: A comma-separated list of fields to filter the response.
    ///   - additionalTypes: A set of item types to include (track, episode).
    ///   - maxItems: Optional limit on total items to stream.
    /// - Returns: AsyncStream that yields `PlaylistTrackItem` objects.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
    public func streamItems(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil,
        maxItems: Int? = nil
    ) -> AsyncThrowingStream<PlaylistTrackItem, Error> {
        playlistItemsProvider(
            id,
            market: market,
            fields: fields,
            additionalTypes: additionalTypes,
            defaultMaxItems: nil
        ).stream(maxItems: maxItems)
    }

    /// Streams entire `Page` batches of playlist items for scenarios that prefer chunked updates.
    ///
    /// - Parameters mirror ``streamItems`` but replace `maxItems` with `maxPages`.
    /// - Returns: Async sequence yielding raw playlist item pages.
    public func streamItemPages(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil,
        maxPages: Int? = nil
    ) -> AsyncThrowingStream<Page<PlaylistTrackItem>, Error> {
        playlistItemsProvider(
            id,
            market: market,
            fields: fields,
            additionalTypes: additionalTypes,
            defaultMaxItems: nil
        ).streamPages(maxPages: maxPages)
    }

    private func playlistItemsProvider(
        _ id: String,
        market: String?,
        fields: String?,
        additionalTypes: Set<AdditionalItemType>?,
        defaultMaxItems: Int?
    ) -> AllItemsProvider<Capability, PlaylistTrackItem> {
        client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) {
            limit, offset in
            try await self.items(
                id,
                market: market,
                fields: fields,
                limit: limit,
                offset: offset,
                additionalTypes: additionalTypes
            )
        }
    }

    /// Get a list of the playlists owned or followed by a specific user.
    /// Corresponds to: `GET /v1/users/{user_id}/playlists`
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` of `SimplifiedPlaylist` objects.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-list-users-playlists)
    public func userPlaylists(userID: String, limit: Int = 20, offset: Int = 0)
        async throws -> Page<SimplifiedPlaylist>
    {
        try validateLimit(limit)
        return
            try await client
            .get("/users/\(userID)/playlists")
            .paginate(limit: limit, offset: offset)
            .decode(Page<SimplifiedPlaylist>.self)
    }

    /// Get the cover image for a playlist.
    /// Corresponds to: `GET /v1/playlists/{id}/images`
    ///
    /// - Parameter id: The Spotify ID for the playlist.
    /// - Returns: A list of `SpotifyImage` objects.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlist-cover)
    public func coverImage(id: String) async throws -> [SpotifyImage] {
        return
            try await client
            .get("/playlists/\(id)/images")
            .decode([SpotifyImage].self)
    }
}

// MARK: - User Access

extension PlaylistsService where Capability == UserAuthCapability {

    /// Get a list of the playlists owned or followed by the current user.
    /// Corresponds to: `GET /v1/me/playlists`. Requires the `playlist-read-private` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` of `SimplifiedPlaylist` objects.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists)
    public func myPlaylists(limit: Int = 20, offset: Int = 0) async throws
        -> Page<SimplifiedPlaylist>
    {
        try validateLimit(limit)
        return
            try await client
            .get("/me/playlists")
            .paginate(limit: limit, offset: offset)
            .decode(Page<SimplifiedPlaylist>.self)
    }

    /// Get all playlists owned or followed by the current user.
    ///
    /// Automatically fetches all pages. Requires the `playlist-read-private` scope.
    ///
    /// - Warning: Fetches up to 1,000 playlists by default. Use `maxItems: nil` to fetch all (may be slow).
    ///
    /// - Parameter maxItems: Limit on total playlists to fetch. Default: 1,000. Use `nil` for unlimited.
    /// - Returns: Array of all `SimplifiedPlaylist` objects.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists)
    public func allMyPlaylists(maxItems: Int? = 1000) async throws -> [SimplifiedPlaylist] {
        try await myPlaylistsProvider(defaultMaxItems: 1000).all(maxItems: maxItems)
    }

    /// Streams the current user's playlists lazily.
    public func streamMyPlaylists(maxItems: Int? = nil)
        -> AsyncThrowingStream<SimplifiedPlaylist, Error>
    {
        myPlaylistsProvider(defaultMaxItems: nil).stream(maxItems: maxItems)
    }

    /// Streams full playlist pages, ideal for batched UI rendering or caching.
    public func streamMyPlaylistPages(maxPages: Int? = nil)
        -> AsyncThrowingStream<Page<SimplifiedPlaylist>, Error>
    {
        myPlaylistsProvider(defaultMaxItems: nil).streamPages(maxPages: maxPages)
    }

    private func myPlaylistsProvider(defaultMaxItems: Int?) -> AllItemsProvider<
        Capability, SimplifiedPlaylist
    > {
        client.makeAllItemsProvider(pageSize: 50, defaultMaxItems: defaultMaxItems) {
            limit, offset in
            try await self.myPlaylists(limit: limit, offset: offset)
        }
    }

    /// Create a new playlist for a Spotify user.
    /// Corresponds to: `POST /v1/users/{user_id}/playlists`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID to create the playlist for.
    ///   - name: The name for the new playlist.
    ///   - isPublic: `true` for public, `false` for private (defaults to true).
    ///   - collaborative: `true` to make collaborative (defaults to false).
    ///   - description: The playlist description.
    /// - Returns: The newly created `Playlist` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/create-playlist)
    public func create(
        for userID: String,
        name: String,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) async throws -> Playlist {
        let body = CreatePlaylistBody(
            name: name, isPublic: isPublic, collaborative: collaborative,
            description: description)
        return
            try await client
            .post("/users/\(userID)/playlists")
            .body(body)
            .decode(Playlist.self)
    }

    /// Change a playlist's details.
    /// Corresponds to: `PUT /v1/playlists/{id}`.
    /// Requires either `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - name: The new name for the playlist.
    ///   - isPublic: `true` for public, `false` for private.
    ///   - collaborative: `true` to make collaborative.
    ///   - description: The new description.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/change-playlist-details)
    public func changeDetails(
        id: String,
        name: String? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) async throws {
        guard name != nil || isPublic != nil || collaborative != nil || description != nil
        else { return }

        let body = ChangePlaylistDetailsBody(
            name: name, isPublic: isPublic, collaborative: collaborative,
            description: description)
        try await client
            .put("/playlists/\(id)")
            .body(body)
            .execute()
    }

    /// Add one or more items to a user's playlist.
    /// Corresponds to: `POST /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to add (max 100).
    ///   - position: The 0-indexed position to insert the items. If omitted, items are appended.
    /// - Returns: A new `snapshotId` for the playlist.
    /// - Throws: `SpotifyError` if the request fails or URI count exceeds 100.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/add-tracks-to-playlist)
    public func add(to id: String, uris: [String], position: Int? = nil) async throws -> String {
        try validateURICount(uris)
        let body = AddPlaylistItemsBody(uris: uris, position: position)
        let snapshot =
            try await client
            .post("/playlists/\(id)/tracks")
            .body(body)
            .decode(SnapshotResponse.self)
        return snapshot.snapshotId
    }

    /// Remove one or more items from a playlist by their URIs.
    /// Corresponds to: `DELETE /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to remove (max 100).
    ///   - snapshotId: The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    /// - Throws: `SpotifyError` if the request fails or URI count exceeds 100.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-tracks-playlist)
    public func remove(from id: String, uris: [String], snapshotId: String? = nil) async throws
        -> String
    {
        try validateURICount(uris)
        let body = RemovePlaylistItemsBody.byURIs(uris, snapshotId: snapshotId)
        let snapshot =
            try await client
            .delete("/playlists/\(id)/tracks")
            .body(body)
            .decode(SnapshotResponse.self)
        return snapshot.snapshotId
    }

    /// Remove one or more items from a playlist by their positions.
    /// Corresponds to: `DELETE /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - positions: An array of 0-indexed positions of tracks to remove (max 100).
    ///   - snapshotId: The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    /// - Throws: `SpotifyError` if the request fails or position count exceeds 100.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/remove-tracks-playlist)
    public func remove(from id: String, positions: [Int], snapshotId: String? = nil) async throws
        -> String
    {
        try validatePositionCount(positions)
        let body = RemovePlaylistItemsBody.byPositions(positions, snapshotId: snapshotId)
        let snapshot =
            try await client
            .delete("/playlists/\(id)/tracks")
            .body(body)
            .decode(SnapshotResponse.self)
        return snapshot.snapshotId
    }

    /// Reorder items in a playlist.
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - rangeStart: The 0-indexed position of the first item to move.
    ///   - insertBefore: The 0-indexed position to move the items to.
    ///   - rangeLength: The number of items to move. Defaults to 1.
    ///   - snapshotId: The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/reorder-or-replace-playlists-tracks)
    public func reorder(
        id: String,
        rangeStart: Int,
        insertBefore: Int,
        rangeLength: Int? = nil,
        snapshotId: String? = nil
    ) async throws -> String {
        let body = ReorderPlaylistItemsBody(
            rangeStart: rangeStart, insertBefore: insertBefore, rangeLength: rangeLength,
            snapshotId: snapshotId)
        let snapshot =
            try await client
            .put("/playlists/\(id)/tracks")
            .body(body)
            .decode(SnapshotResponse.self)
        return snapshot.snapshotId
    }

    /// Replace all items in a playlist.
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to set (max 100).
    /// - Throws: `SpotifyError` if the request fails or URI count exceeds 100.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/reorder-or-replace-playlists-tracks)
    public func replace(itemsIn id: String, with uris: [String]) async throws {
        try validateURICount(uris)
        try await client
            .put("/playlists/\(id)/tracks")
            .query("uris", uris.joined(separator: ","))
            .execute()
    }

    /// Upload a custom cover image for a playlist.
    /// Corresponds to: `PUT /v1/playlists/{id}/images`. Requires `ugc-image-upload` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - jpegData: The raw image data (must be a JPEG).
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/upload-custom-playlist-cover)
    public func uploadCoverImage(for id: String, jpegData: Data) async throws {
        let base64 = jpegData.base64EncodedData()
        let url = await client.apiURL(path: "/playlists/\(id)/images")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = base64
        urlRequest.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await client.authorizedRequest(urlRequest)
        guard (200..<300).contains(response.statusCode) else {
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode, body: "Image upload failed")
        }
    }

    /// Add the current user as a follower of a playlist.
    /// Corresponds to: `PUT /v1/playlists/{id}/followers`.
    /// Requires the `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - isPublic: If true, the playlist will be public.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/follow-playlist)
    public func follow(_ id: String, isPublic: Bool = true) async throws {
        let body = FollowPlaylistBody(isPublic: isPublic)
        try await client
            .put("/playlists/\(id)/followers")
            .body(body)
            .execute()
    }

    /// Remove the current user as a follower of a playlist.
    /// Corresponds to: `DELETE /v1/playlists/{id}/followers`.
    ///
    /// - Parameter id: The Spotify ID for the playlist.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/unfollow-playlist)
    public func unfollow(_ id: String) async throws {
        try await client
            .delete("/playlists/\(id)/followers")
            .execute()
    }
}

// MARK: - Helper Methods

extension PlaylistsService {
    fileprivate func validateURICount(_ uris: [String]) throws {
        guard uris.count <= SpotifyAPILimits.Playlists.itemMutationBatchSize else {
            throw SpotifyClientError.invalidRequest(
                reason:
                    "Maximum of \(SpotifyAPILimits.Playlists.itemMutationBatchSize) URIs allowed per request. You provided \(uris.count)."
            )
        }
        for uri in uris {
            try validateURI(uri)
        }
    }

    fileprivate func validatePositionCount(_ positions: [Int]) throws {
        guard positions.count <= SpotifyAPILimits.Playlists.positionMutationBatchSize else {
            throw SpotifyClientError.invalidRequest(
                reason:
                    "Maximum of \(SpotifyAPILimits.Playlists.positionMutationBatchSize) positions allowed per request. You provided \(positions.count)."
            )
        }
    }
}

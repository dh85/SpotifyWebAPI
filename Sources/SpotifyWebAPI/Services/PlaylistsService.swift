import Foundation

private struct SnapshotResponse: Decodable, Sendable { let snapshotId: String }
private struct FollowPlaylistBody: Encodable, Sendable {
    let isPublic: Bool?
    enum CodingKeys: String, CodingKey { case isPublic = "public" }
}

private struct AddPlaylistItemsBody: Encodable, Sendable {
    let uris: [String]
    let position: Int?
}

private struct ChangePlaylistDetailsBody: Encodable, Sendable {
    let name: String?
    let isPublic: Bool?
    let collaborative: Bool?
    let description: String?
    enum CodingKeys: String, CodingKey {
        case name, collaborative, description
        case isPublic = "public"
    }
}

private struct CreatePlaylistBody: Encodable, Sendable {
    let name: String
    let isPublic: Bool?
    let collaborative: Bool?
    let description: String?
    enum CodingKeys: String, CodingKey {
        case name, collaborative, description
        case isPublic = "public"
    }
}

private struct ReorderPlaylistItemsBody: Encodable, Sendable {
    let rangeStart: Int
    let insertBefore: Int
    let rangeLength: Int?
    let snapshotId: String?
    enum CodingKeys: String, CodingKey {
        case rangeStart = "range_start"
        case insertBefore = "insert_before"
        case rangeLength = "range_length"
        case snapshotId = "snapshot_id"
    }
}

private struct RemovePlaylistItemsBody: Encodable, Sendable {
    let tracks: [TrackURIObject]?
    let positions: [Int]?
    let snapshotId: String?

    enum CodingKeys: String, CodingKey {
        case tracks, positions
        case snapshotId = "snapshot_id"
    }

    static func byURIs(_ uris: [String], snapshotId: String? = nil) -> Self {
        let trackObjects = uris.map { TrackURIObject(uri: $0) }
        return .init(
            tracks: trackObjects,
            positions: nil,
            snapshotId: snapshotId
        )
    }

    static func byPositions(_ positions: [Int], snapshotId: String? = nil)
        -> Self
    {
        return .init(tracks: [], positions: positions, snapshotId: snapshotId)
    }
}

private struct TrackURIObject: Encodable, Sendable { let uri: String }

/// A service for interacting with Spotify Playlists, managing items, and updating details.
public struct PlaylistsService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Public Capability
extension PlaylistsService where Capability: PublicSpotifyCapability {

    /// Get a playlist owned by a Spotify user.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - fields: Optional. A comma-separated list of fields to filter the response.
    ///   - additionalTypes: Optional. A list of types to include (e.g., "track", "episode").
    /// - Returns: A full `Playlist` object.
    public func get(
        _ id: String,
        market: String? = nil,
        fields: String? = nil,
        additionalTypes: [String]? = nil
    ) async throws -> Playlist {

        var queryItems: [URLQueryItem] = []
        if let market {
            queryItems.append(.init(name: "market", value: market))
        }
        if let fields {
            queryItems.append(.init(name: "fields", value: fields))
        }
        if let types = additionalTypes?.joined(separator: ",") {
            queryItems.append(.init(name: "additional_types", value: types))
        }

        let request = SpotifyRequest<Playlist>.get(
            "/playlists/\(id)",
            query: queryItems
        )
        return try await client.perform(request)
    }

    /// Get the tracks or episodes in a playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}/tracks`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - fields: Optional. A comma-separated list of fields to filter the response.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - additionalTypes: Optional. A list of types to include (e.g., "track", "episode").
    /// - Returns: A `Page` object containing `PlaylistTrackItem` items.
    public func items(
        _ id: String,
        market: String? = nil,  // FIX: Pass market
        fields: String? = nil,  // FIX: Pass fields
        limit: Int = 20,
        offset: Int = 0,
        additionalTypes: [String]? = nil  // FIX: Pass additionalTypes
    ) async throws -> Page<PlaylistTrackItem> {

        let clampedLimit = min(max(limit, 1), 50)

        var queryItems: [URLQueryItem] = [
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]
        if let market {
            queryItems.append(.init(name: "market", value: market))
        }
        if let fields {
            queryItems.append(.init(name: "fields", value: fields))
        }
        if let types = additionalTypes?.joined(separator: ",") {
            queryItems.append(.init(name: "additional_types", value: types))
        }

        let request = SpotifyRequest<Page<PlaylistTrackItem>>.get(
            "/playlists/\(id)/tracks",
            query: queryItems
        )
        return try await client.perform(request)
    }

    /// Get a list of the playlists owned or followed by a specific user.
    ///
    /// Corresponds to: `GET /v1/users/{user_id}/playlists`.
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` of `SimplifiedPlaylist` objects.
    public func userPlaylists(userID: String, limit: Int = 20, offset: Int = 0)
        async throws -> Page<SimplifiedPlaylist>
    {
        let queryItems: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        let request = SpotifyRequest<Page<SimplifiedPlaylist>>.get(
            "/users/\(userID)/playlists",
            query: queryItems
        )
        return try await client.perform(request)
    }

    /// Get the cover image for a playlist.
    ///
    /// Corresponds to: `GET /v1/playlists/{id}/images`.
    ///
    /// - Parameter id: The Spotify ID for the playlist.
    /// - Returns: A list of `SpotifyImage` objects.
    public func coverImage(id: String) async throws -> [SpotifyImage] {
        let request = SpotifyRequest<[SpotifyImage]>.get(
            "/playlists/\(id)/images"
        )
        return try await client.perform(request)
    }
}

// MARK: - User Capability
extension PlaylistsService where Capability == UserAuthCapability {

    /// Get a list of the playlists owned or followed by the current user.
    ///
    /// Corresponds to: `GET /v1/me/playlists`.
    /// Requires the `playlist-read-private` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` of `SimplifiedPlaylist` objects.
    public func myPlaylists(limit: Int = 20, offset: Int = 0) async throws
        -> Page<SimplifiedPlaylist>
    {
        let queryItems: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        let request = SpotifyRequest<Page<SimplifiedPlaylist>>.get(
            "/me/playlists",
            query: queryItems
        )
        return try await client.perform(request)
    }

    /// Create a new playlist for a Spotify user.
    ///
    /// Corresponds to: `POST /v1/users/{user_id}/playlists`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - userID: The Spotify user ID to create the playlist for.
    ///   - name: The name for the new playlist.
    ///   - isPublic: Optional. `true` for public, `false` for private.
    /// - Returns: The newly created `Playlist` object.
    public func create(for userID: String, name: String, isPublic: Bool? = nil)
        async throws -> Playlist
    {
        let body = CreatePlaylistBody(
            name: name,
            isPublic: isPublic,
            collaborative: nil,
            description: nil
        )
        let request = SpotifyRequest<Playlist>.post(
            "/users/\(userID)/playlists",
            body: body
        )
        return try await client.perform(request)
    }

    /// Change a playlist's details.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}`.
    /// Requires either `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - name: Optional. The new name for the playlist.
    ///   - isPublic: Optional. `true` for public, `false` for private.
    ///   - collaborative: Optional. `true` to make collaborative.
    ///   - description: Optional. The new description.
    public func changeDetails(
        id: String,
        name: String? = nil,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) async throws {
        guard
            name != nil || isPublic != nil || collaborative != nil
                || description != nil
        else {
            return
        }

        let body = ChangePlaylistDetailsBody(
            name: name,
            isPublic: isPublic,
            collaborative: collaborative,
            description: description
        )

        let request = SpotifyRequest<EmptyResponse>.put(
            "/playlists/\(id)",
            body: body
        )
        let _: EmptyResponse = try await client.perform(request)
    }

    /// Add one or more items to a user's playlist.
    ///
    /// Corresponds to: `POST /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to add.
    /// - Returns: A new `snapshotId` for the playlist.
    public func add(to id: String, uris: [String]) async throws -> String {
        let body = AddPlaylistItemsBody(uris: uris, position: nil)
        let request = SpotifyRequest<SnapshotResponse>.post(
            "/playlists/\(id)/tracks",
            body: body
        )
        let snapshot = try await client.perform(request)
        return snapshot.snapshotId
    }

    /// Remove one or more items from a playlist by their URIs.
    ///
    /// Corresponds to: `DELETE /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to remove.
    /// - Returns: A new `snapshotId` for the playlist.
    public func remove(from id: String, uris: [String]) async throws -> String {
        let body = RemovePlaylistItemsBody.byURIs(uris)
        let request = SpotifyRequest<SnapshotResponse>.delete(
            "/playlists/\(id)/tracks",
            body: body
        )
        let snapshot = try await client.perform(request)
        return snapshot.snapshotId
    }

    /// Reorder items in a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - rangeStart: The 0-indexed position of the first item to move.
    ///   - insertBefore: The 0-indexed position to move the items to.
    ///   - rangeLength: Optional. The number of items to move. Defaults to 1.
    ///   - snapshotId: Optional. The playlist's snapshot ID.
    /// - Returns: A new `snapshotId` for the playlist.
    public func reorder(
        id: String,
        rangeStart: Int,
        insertBefore: Int,
        rangeLength: Int? = nil,
        snapshotId: String? = nil
    ) async throws -> String {
        let body = ReorderPlaylistItemsBody(
            rangeStart: rangeStart,
            insertBefore: insertBefore,
            rangeLength: rangeLength,
            snapshotId: snapshotId
        )
        let request = SpotifyRequest<SnapshotResponse>.put(
            "/playlists/\(id)/tracks",
            body: body
        )
        let snapshot = try await client.perform(request)
        return snapshot.snapshotId
    }

    /// Replace all items in a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/tracks`.
    /// Requires `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - uris: A list of track/episode URIs to set.
    public func replace(itemsIn id: String, with uris: [String]) async throws {
        let query: [URLQueryItem] = [
            .init(name: "uris", value: uris.joined(separator: ","))
        ]
        let request = SpotifyRequest<EmptyResponse>.put(
            "/playlists/\(id)/tracks",
            query: query
        )
        let _: EmptyResponse = try await client.perform(request)
    }

    /// Upload a custom cover image for a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/images`.
    /// Requires `ugc-image-upload` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - jpegData: The raw image data (must be a JPEG).
    public func uploadCoverImage(for id: String, jpegData: Data) async throws {
        // The API requires Base64 encoded string as the body, not raw data
        let base64 = jpegData.base64EncodedData()

        let (_, response) = try await client.authorizedRequest(
            url: client.apiURL(path: "/playlists/\(id)/images"),  // Manually building URL for raw data
            method: "PUT",
            body: base64,
            contentType: "image/jpeg"
        )

        guard (200..<300).contains(response.statusCode) else {
            throw SpotifyAuthError.httpError(
                statusCode: response.statusCode,
                body: "Image upload failed"
            )
        }
    }

    /// Add the current user as a follower of a playlist.
    ///
    /// Corresponds to: `PUT /v1/playlists/{id}/followers`.
    /// Requires the `playlist-modify-public` or `playlist-modify-private` scope.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the playlist.
    ///   - isPublic: Optional. If true, the playlist will be public.
    public func follow(_ id: String, isPublic: Bool = true) async throws {
        let body = FollowPlaylistBody(isPublic: isPublic)
        let request = SpotifyRequest<EmptyResponse>.put(
            "/playlists/\(id)/followers",
            body: body
        )
        let _: EmptyResponse = try await client.perform(request)
    }

    /// Remove the current user as a follower of a playlist.
    ///
    /// Corresponds to: `DELETE /v1/playlists/{id}/followers`.
    ///
    /// - Parameter id: The Spotify ID for the playlist.
    public func unfollow(_ id: String) async throws {
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/playlists/\(id)/followers"
        )
        let _: EmptyResponse = try await client.perform(request)
    }
}

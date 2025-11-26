import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Minimal surface for fetching user profile information.
public protocol SpotifyUsersAPI: Sendable {
    func me() async throws -> CurrentUserProfile
    func topArtists(
        timeRange: TimeRange,
        limit: Int,
        offset: Int
    ) async throws -> Page<Artist>
    func topTracks(
        timeRange: TimeRange,
        limit: Int,
        offset: Int
    ) async throws -> Page<Track>
}

extension SpotifyUsersAPI {
    public func topArtists(
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20
    ) async throws -> Page<Artist> {
        try await topArtists(timeRange: timeRange, limit: limit, offset: 0)
    }

    public func topTracks(
        timeRange: TimeRange = .mediumTerm,
        limit: Int = 20
    ) async throws -> Page<Track> {
        try await topTracks(timeRange: timeRange, limit: limit, offset: 0)
    }
}

/// Minimal surface for album lookups.
public protocol SpotifyAlbumsAPI: Sendable {
    func get(_ id: String) async throws -> Album
}

/// Minimal surface for track lookups.
public protocol SpotifyTracksAPI: Sendable {
    func get(_ id: String) async throws -> Track
}

/// Minimal surface for artist lookups.
public protocol SpotifyArtistsAPI: Sendable {
    func get(_ id: String) async throws -> Artist
}

/// Minimal surface for search operations.
public protocol SpotifySearchAPI: Sendable {
    func search(
        query: String,
        types: Set<SearchType>,
        limit: Int,
        offset: Int
    ) async throws -> SearchResults
}

extension SpotifySearchAPI {
    public func search(
        query: String,
        types: Set<SearchType>
    ) async throws -> SearchResults {
        try await search(query: query, types: types, limit: 20, offset: 0)
    }
}

/// Minimal playlist operations exposed to consumer code.
public protocol SpotifyPlaylistsAPI: Sendable {
    func get(_ id: String) async throws -> Playlist
    func myPlaylists(limit: Int, offset: Int) async throws -> Page<SimplifiedPlaylist>
}

extension SpotifyPlaylistsAPI {
    public func myPlaylists() async throws -> Page<SimplifiedPlaylist> {
        try await myPlaylists(limit: 20, offset: 0)
    }
}

/// Playback controls required by most UIs.
public protocol SpotifyPlayerAPI: Sendable {
    func pause(deviceID: String?) async throws
    func resume(deviceID: String?) async throws
    func state(
        market: String?,
        additionalTypes: Set<AdditionalItemType>?
    ) async throws -> PlaybackState?
    func recentlyPlayed(
        limit: Int,
        after: Date?,
        before: Date?
    ) async throws -> CursorBasedPage<PlayHistoryItem>
}

extension SpotifyPlayerAPI {
    public func pause() async throws {
        try await pause(deviceID: nil)
    }

    public func resume() async throws {
        try await resume(deviceID: nil)
    }

    public func state() async throws -> PlaybackState? {
        try await state(market: nil, additionalTypes: nil)
    }

    public func recentlyPlayed(limit: Int = 20) async throws -> CursorBasedPage<PlayHistoryItem> {
        try await recentlyPlayed(limit: limit, after: nil, before: nil)
    }
}

/// A lightweight protocol mirroring the ``SpotifyClient`` factory categories
/// (`albums`, `playlists`, `tracks`, etc.). Adopt this protocol in your own
/// components to keep dependency injection and testing ergonomic.
///
/// The concrete ``SpotifyClient`` already conforms (for user-authenticated
/// clients), and ``MockSpotifyClient`` can be dropped in anywhere the protocol
/// is expected. Pair it with ``SpotifyTestFixtures`` to build realistic stub
/// data in a single line.
public protocol SpotifyClientProtocol: Sendable {
    /// Raw endpoints used by the helper extension below.
    var usersAPI: any SpotifyUsersAPI { get }
    var albumsAPI: any SpotifyAlbumsAPI { get }
    var tracksAPI: any SpotifyTracksAPI { get }
    var artistsAPI: any SpotifyArtistsAPI { get }
    var searchAPI: any SpotifySearchAPI { get }
    var playlistsAPI: any SpotifyPlaylistsAPI { get }
    var playerAPI: any SpotifyPlayerAPI { get }
}

extension SpotifyClientProtocol {
    /// Mirrors ``SpotifyClient/users`` so consumers can keep writing `client.users.me()`.
    public var users: any SpotifyUsersAPI { usersAPI }
    public var albums: any SpotifyAlbumsAPI { albumsAPI }
    public var tracks: any SpotifyTracksAPI { tracksAPI }
    public var artists: any SpotifyArtistsAPI { artistsAPI }
    public var search: any SpotifySearchAPI { searchAPI }
    public var playlists: any SpotifyPlaylistsAPI { playlistsAPI }
    public var player: any SpotifyPlayerAPI { playerAPI }
}

extension SpotifyClient: SpotifyClientProtocol where Capability == UserAuthCapability {
    public nonisolated var usersAPI: any SpotifyUsersAPI {
        LiveUsersAPI(client: self)
    }

    public nonisolated var albumsAPI: any SpotifyAlbumsAPI {
        LiveAlbumsAPI(client: self)
    }

    public nonisolated var tracksAPI: any SpotifyTracksAPI {
        LiveTracksAPI(client: self)
    }

    public nonisolated var artistsAPI: any SpotifyArtistsAPI {
        LiveArtistsAPI(client: self)
    }

    public nonisolated var searchAPI: any SpotifySearchAPI {
        LiveSearchAPI(client: self)
    }

    public nonisolated var playlistsAPI: any SpotifyPlaylistsAPI {
        LivePlaylistsAPI(client: self)
    }

    public nonisolated var playerAPI: any SpotifyPlayerAPI {
        LivePlayerAPI(client: self)
    }
}

// MARK: - Live API Base

/// Base protocol for Live API wrappers that forward to SpotifyClient.
private protocol LiveAPIWrapper {
    var client: SpotifyClient<UserAuthCapability> { get }
}

// MARK: - Live API Implementations

private struct LiveUsersAPI: SpotifyUsersAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func me() async throws -> CurrentUserProfile {
        try await client.users.me()
    }

    func topArtists(
        timeRange: TimeRange,
        limit: Int,
        offset: Int
    ) async throws -> Page<Artist> {
        try await client.users.topArtists(timeRange: timeRange, limit: limit, offset: offset)
    }

    func topTracks(
        timeRange: TimeRange,
        limit: Int,
        offset: Int
    ) async throws -> Page<Track> {
        try await client.users.topTracks(timeRange: timeRange, limit: limit, offset: offset)
    }
}

private struct LiveAlbumsAPI: SpotifyAlbumsAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Album {
        try await client.albums.get(id)
    }
}

private struct LiveTracksAPI: SpotifyTracksAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Track {
        try await client.tracks.get(id)
    }
}

private struct LiveArtistsAPI: SpotifyArtistsAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Artist {
        try await client.artists.get(id)
    }
}

private struct LiveSearchAPI: SpotifySearchAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func search(
        query: String,
        types: Set<SearchType>,
        limit: Int,
        offset: Int
    ) async throws -> SearchResults {
        try await client.search.search(
            query: query,
            types: types,
            limit: limit,
            offset: offset
        )
    }
}

private struct LivePlaylistsAPI: SpotifyPlaylistsAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Playlist {
        try await client.playlists.get(id)
    }

    func myPlaylists(
        limit: Int,
        offset: Int
    ) async throws -> Page<SimplifiedPlaylist> {
        try await client.playlists.myPlaylists(limit: limit, offset: offset)
    }
}

private struct LivePlayerAPI: SpotifyPlayerAPI, LiveAPIWrapper {
    let client: SpotifyClient<UserAuthCapability>

    func pause(deviceID: String?) async throws {
        try await client.player.pause(deviceID: deviceID)
    }

    func resume(deviceID: String?) async throws {
        try await client.player.resume(deviceID: deviceID)
    }

    func state(
        market: String?,
        additionalTypes: Set<AdditionalItemType>?
    ) async throws -> PlaybackState? {
        try await client.player.state(market: market, additionalTypes: additionalTypes)
    }

    func recentlyPlayed(
        limit: Int,
        after: Date?,
        before: Date?
    ) async throws -> CursorBasedPage<PlayHistoryItem> {
        try await client.player.recentlyPlayed(limit: limit, after: after, before: before)
    }
}

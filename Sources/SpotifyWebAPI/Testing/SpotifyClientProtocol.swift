import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Minimal surface for fetching user profile information.
public protocol SpotifyUsersAPI: Sendable {
    func me() async throws -> CurrentUserProfile
}

/// Minimal surface for album lookups.
public protocol SpotifyAlbumsAPI: Sendable {
    func get(_ id: String) async throws -> Album
}

/// Minimal surface for track lookups.
public protocol SpotifyTracksAPI: Sendable {
    func get(_ id: String) async throws -> Track
}

/// Minimal playlist operations exposed to consumer code.
public protocol SpotifyPlaylistsAPI: Sendable {
    func get(_ id: String) async throws -> Playlist
    func myPlaylists(limit: Int, offset: Int) async throws -> Page<SimplifiedPlaylist>
}

public extension SpotifyPlaylistsAPI {
    func myPlaylists() async throws -> Page<SimplifiedPlaylist> {
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
}

public extension SpotifyPlayerAPI {
    func pause() async throws {
        try await pause(deviceID: nil)
    }

    func resume() async throws {
        try await resume(deviceID: nil)
    }

    func state() async throws -> PlaybackState? {
        try await state(market: nil, additionalTypes: nil)
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
    var playlistsAPI: any SpotifyPlaylistsAPI { get }
    var playerAPI: any SpotifyPlayerAPI { get }
}

public extension SpotifyClientProtocol {
    /// Mirrors ``SpotifyClient/users`` so consumers can keep writing `client.users.me()`.
    var users: any SpotifyUsersAPI { usersAPI }
    var albums: any SpotifyAlbumsAPI { albumsAPI }
    var tracks: any SpotifyTracksAPI { tracksAPI }
    var playlists: any SpotifyPlaylistsAPI { playlistsAPI }
    var player: any SpotifyPlayerAPI { playerAPI }
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

    public nonisolated var playlistsAPI: any SpotifyPlaylistsAPI {
        LivePlaylistsAPI(client: self)
    }

    public nonisolated var playerAPI: any SpotifyPlayerAPI {
        LivePlayerAPI(client: self)
    }
}

private struct LiveUsersAPI: SpotifyUsersAPI {
    let client: SpotifyClient<UserAuthCapability>

    func me() async throws -> CurrentUserProfile {
        try await client.users.me()
    }
}

private struct LiveAlbumsAPI: SpotifyAlbumsAPI {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Album {
        try await client.albums.get(id)
    }
}

private struct LiveTracksAPI: SpotifyTracksAPI {
    let client: SpotifyClient<UserAuthCapability>

    func get(_ id: String) async throws -> Track {
        try await client.tracks.get(id)
    }
}

private struct LivePlaylistsAPI: SpotifyPlaylistsAPI {
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

private struct LivePlayerAPI: SpotifyPlayerAPI {
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
}

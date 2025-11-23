import Foundation

/// A mock Spotify client for testing consumer code.
///
/// Adopt ``SpotifyClientProtocol`` in the code under test and supply this mock
/// to avoid making real API calls. ``SpotifyTestFixtures`` provides handy model
/// builders so you can configure responses in a single line.
///
/// ```swift
/// import Testing
/// import SpotifyWebAPI
///
/// struct MyViewModel {
///     private let client: any SpotifyClientProtocol
///
///     init(client: any SpotifyClientProtocol) {
///         self.client = client
///     }
///
///     func loadProfile() async throws -> String {
///         let profile = try await client.users.me()
///         return profile.displayName ?? "Unknown"
///     }
/// }
///
/// struct MyViewModelTests {
///     @Test
///     func loadProfileUpdatesName() async throws {
///         let mock = MockSpotifyClient()
///         mock.mockProfile = SpotifyTestFixtures.currentUserProfile(
///             id: "test",
///             displayName: "Test User"
///         )
///
///         let viewModel = MyViewModel(client: mock)
///         let name = try await viewModel.loadProfile()
///
///         #expect(name == "Test User")
///     }
/// }
/// ```
public final class MockSpotifyClient: SpotifyClientProtocol, @unchecked Sendable {

    // MARK: - State Isolation

    private let state: LockIsolated<MockState>

    // MARK: - Mock Data

    public var mockProfile: CurrentUserProfile? {
        get { state.withValue { $0.mockProfile } }
        set { state.withValue { $0.mockProfile = newValue } }
    }

    public var mockAlbum: Album? {
        get { state.withValue { $0.mockAlbum } }
        set { state.withValue { $0.mockAlbum = newValue } }
    }

    public var mockTrack: Track? {
        get { state.withValue { $0.mockTrack } }
        set { state.withValue { $0.mockTrack = newValue } }
    }

    public var mockPlaylist: Playlist? {
        get { state.withValue { $0.mockPlaylist } }
        set { state.withValue { $0.mockPlaylist = newValue } }
    }

    public var mockPlaylists: [SimplifiedPlaylist] {
        get { state.withValue { $0.mockPlaylists } }
        set { state.withValue { $0.mockPlaylists = newValue } }
    }

    public var mockPlaylistsTotal: Int? {
        get { state.withValue { $0.mockPlaylistsTotal } }
        set { state.withValue { $0.mockPlaylistsTotal = newValue } }
    }

    public var mockPlaylistsHref: URL {
        get { state.withValue { $0.mockPlaylistsHref } }
        set { state.withValue { $0.mockPlaylistsHref = newValue } }
    }

    public var mockArtist: Artist? {
        get { state.withValue { $0.mockArtist } }
        set { state.withValue { $0.mockArtist = newValue } }
    }

    public var mockPlaybackState: PlaybackState? {
        get { state.withValue { $0.mockPlaybackState } }
        set { state.withValue { $0.mockPlaybackState = newValue } }
    }

    public var mockError: Error? {
        get { state.withValue { $0.mockError } }
        set { state.withValue { $0.mockError = newValue } }
    }

    // MARK: - Protocol Surfaces

    public var usersAPI: any SpotifyUsersAPI { usersService }
    public var albumsAPI: any SpotifyAlbumsAPI { albumsService }
    public var tracksAPI: any SpotifyTracksAPI { tracksService }
    public var playlistsAPI: any SpotifyPlaylistsAPI { playlistsService }
    public var playerAPI: any SpotifyPlayerAPI { playerService }

    // MARK: - Call Tracking

    public var getUsersCalled: Bool { state.withValue { $0.getUsersCalled } }
    public var getAlbumCalled: Bool { state.withValue { $0.getAlbumCalled } }
    public var getTrackCalled: Bool { state.withValue { $0.getTrackCalled } }
    public var getPlaylistCalled: Bool { state.withValue { $0.getPlaylistCalled } }
    public var myPlaylistsCalled: Bool { state.withValue { $0.myPlaylistsCalled } }
    public var myPlaylistsParameters: [(limit: Int, offset: Int)] {
        state.withValue { $0.myPlaylistsParameters }
    }
    public var pauseCalled: Bool { state.withValue { $0.pauseCalled } }
    public var playCalled: Bool { state.withValue { $0.playCalled } }

    private lazy var usersService = UsersAPI(client: self)
    private lazy var albumsService = AlbumsAPI(client: self)
    private lazy var tracksService = TracksAPI(client: self)
    private lazy var playlistsService = PlaylistsAPI(client: self)
    private lazy var playerService = PlayerAPI(client: self)

    public init(playlistsHref: URL = URL(string: "https://api.spotify.com/v1/me/playlists")!) {
        self.state = LockIsolated(MockState(playlistsHref: playlistsHref))
    }

    // MARK: - Reset

    /// Reset all mock data and call tracking.
    public func reset() {
        state.withValue { $0.reset() }
    }

    // MARK: - Helpers

    fileprivate func resolve<T>(_ value: T?, label: String) throws -> T {
        guard let value else {
            throw MockError.noMockData(label)
        }
        return value
    }

    fileprivate func makePlaylistsPage(limit: Int, offset: Int) -> Page<SimplifiedPlaylist> {
        state.withValue { state in
            let total = state.mockPlaylistsTotal ?? state.mockPlaylists.count
            let items = Array(
                state.mockPlaylists
                    .dropFirst(min(offset, state.mockPlaylists.count))
                    .prefix(max(limit, 0))
            )
            let nextOffset = offset + limit
            let nextURL =
                nextOffset < total
                ? Self.makePageURL(
                    limit: limit,
                    offset: nextOffset,
                    baseURL: state.mockPlaylistsHref
                )
                : nil
            let previousOffset = max(offset - limit, 0)
            let previousURL =
                offset > 0
                ? Self.makePageURL(
                    limit: limit,
                    offset: previousOffset,
                    baseURL: state.mockPlaylistsHref
                )
                : nil

            return Page(
                href: state.mockPlaylistsHref,
                items: items,
                limit: limit,
                next: nextURL,
                offset: offset,
                previous: previousURL,
                total: total
            )
        }
    }

    private static func makePageURL(limit: Int, offset: Int, baseURL: URL) -> URL? {
        guard limit > 0 else { return nil }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var queryItems =
            components?.queryItems?.filter { $0.name != "limit" && $0.name != "offset" } ?? []
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        components?.queryItems = queryItems
        return components?.url
    }
    private final class UsersAPI: SpotifyUsersAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func me() async throws -> CurrentUserProfile {
            try client.state.withValue { state in
                state.getUsersCalled = true
                if let error = state.mockError { throw error }
                return try client.resolve(state.mockProfile, label: "mockProfile")
            }
        }
    }

    private final class AlbumsAPI: SpotifyAlbumsAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Album {
            try client.state.withValue { state in
                state.getAlbumCalled = true
                if let error = state.mockError { throw error }
                return try client.resolve(state.mockAlbum, label: "mockAlbum")
            }
        }
    }

    private final class TracksAPI: SpotifyTracksAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Track {
            try client.state.withValue { state in
                state.getTrackCalled = true
                if let error = state.mockError { throw error }
                return try client.resolve(state.mockTrack, label: "mockTrack")
            }
        }
    }

    private final class PlaylistsAPI: SpotifyPlaylistsAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Playlist {
            try client.state.withValue { state in
                state.getPlaylistCalled = true
                if let error = state.mockError { throw error }
                return try client.resolve(state.mockPlaylist, label: "mockPlaylist")
            }
        }

        func myPlaylists(limit: Int, offset: Int) async throws -> Page<SimplifiedPlaylist> {
            try client.state.withValue { state in
                state.myPlaylistsCalled = true
                state.myPlaylistsParameters.append((limit: limit, offset: offset))
                if let error = state.mockError { throw error }
            }
            return client.makePlaylistsPage(limit: max(0, limit), offset: max(0, offset))
        }
    }

    private final class PlayerAPI: SpotifyPlayerAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func pause(deviceID: String?) async throws {
            try client.state.withValue { state in
                state.pauseCalled = true
                if let error = state.mockError { throw error }
            }
        }

        func resume(deviceID: String?) async throws {
            try client.state.withValue { state in
                state.playCalled = true
                if let error = state.mockError { throw error }
            }
        }

        func state(
            market: String?,
            additionalTypes: Set<AdditionalItemType>?
        ) async throws -> PlaybackState? {
            try client.state.withValue { state in
                if let error = state.mockError { throw error }
                return state.mockPlaybackState
            }
        }
    }
}

// MARK: - Mock Error

public enum MockError: Error, Equatable {
    case noMockData(String)
}

// MARK: - Private Helpers

private struct MockState {
    var mockProfile: CurrentUserProfile?
    var mockAlbum: Album?
    var mockTrack: Track?
    var mockPlaylist: Playlist?
    var mockPlaylists: [SimplifiedPlaylist]
    var mockPlaylistsTotal: Int?
    var mockPlaylistsHref: URL
    let defaultPlaylistsHref: URL
    var mockArtist: Artist?
    var mockPlaybackState: PlaybackState?
    var mockError: Error?

    var getUsersCalled = false
    var getAlbumCalled = false
    var getTrackCalled = false
    var getPlaylistCalled = false
    var myPlaylistsCalled = false
    var myPlaylistsParameters: [(limit: Int, offset: Int)] = []
    var pauseCalled = false
    var playCalled = false

    init(playlistsHref: URL) {
        self.mockPlaylists = []
        self.mockPlaylistsHref = playlistsHref
        self.defaultPlaylistsHref = playlistsHref
    }

    mutating func reset() {
        let href = defaultPlaylistsHref
        self = MockState(playlistsHref: href)
    }
}

private final class LockIsolated<Value> {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    @discardableResult
    func withValue<T>(_ body: (inout Value) throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}

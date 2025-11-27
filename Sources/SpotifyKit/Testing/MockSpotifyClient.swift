import Foundation

// MARK: - Mock API Base Protocol

private protocol MockAPIBase: Sendable {
    var client: MockSpotifyClient { get }
    init(client: MockSpotifyClient)
}

extension MockAPIBase {
    func withMockState<T>(_ body: (inout MockState) throws -> T) rethrows -> T {
        try client.state.withValue(body)
    }
}

// MARK: - MockSpotifyClient

/// A mock Spotify client for testing consumer code.
///
/// Adopt ``SpotifyClientProtocol`` in the code under test and supply this mock
/// to avoid making real API calls. ``SpotifyTestFixtures`` provides handy model
/// builders so you can configure responses in a single line.
///
/// ```swift
/// import Testing
/// import SpotifyKit
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

    fileprivate let state: LockIsolated<MockState>

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

    public var mockSearchResult: SearchResults? {
        get { state.withValue { $0.mockSearchResult } }
        set { state.withValue { $0.mockSearchResult = newValue } }
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

    public var usersAPI: any SpotifyUsersAPI {
        services.withValue { services in
            if services.usersService == nil {
                services.usersService = UsersAPI(client: self)
            }
            return services.usersService!
        }
    }

    public var albumsAPI: any SpotifyAlbumsAPI {
        services.withValue { services in
            if services.albumsService == nil {
                services.albumsService = AlbumsAPI(client: self)
            }
            return services.albumsService!
        }
    }

    public var tracksAPI: any SpotifyTracksAPI {
        services.withValue { services in
            if services.tracksService == nil {
                services.tracksService = TracksAPI(client: self)
            }
            return services.tracksService!
        }
    }

    public var artistsAPI: any SpotifyArtistsAPI {
        services.withValue { services in
            if services.artistsService == nil {
                services.artistsService = ArtistsAPI(client: self)
            }
            return services.artistsService!
        }
    }

    public var searchAPI: any SpotifySearchAPI {
        services.withValue { services in
            if services.searchService == nil {
                services.searchService = SearchAPI(client: self)
            }
            return services.searchService!
        }
    }

    public var playlistsAPI: any SpotifyPlaylistsAPI {
        services.withValue { services in
            if services.playlistsService == nil {
                services.playlistsService = PlaylistsAPI(client: self)
            }
            return services.playlistsService!
        }
    }

    public var playerAPI: any SpotifyPlayerAPI {
        services.withValue { services in
            if services.playerService == nil {
                services.playerService = PlayerAPI(client: self)
            }
            return services.playerService!
        }
    }

    // MARK: - Call Tracking

    public var getUsersCalled: Bool { state.withValue { $0.getUsersCalled } }
    public var getAlbumCalled: Bool { state.withValue { $0.getAlbumCalled } }
    public var getTrackCalled: Bool { state.withValue { $0.getTrackCalled } }
    public var getArtistCalled: Bool { state.withValue { $0.getArtistCalled } }
    public var searchCalled: Bool { state.withValue { $0.searchCalled } }
    public var searchParameters: [(query: String, types: Set<SearchType>, limit: Int, offset: Int)]
    {
        state.withValue { $0.searchParameters }
    }
    public var getPlaylistCalled: Bool { state.withValue { $0.getPlaylistCalled } }
    public var myPlaylistsCalled: Bool { state.withValue { $0.myPlaylistsCalled } }
    public var myPlaylistsParameters: [(limit: Int, offset: Int)] {
        state.withValue { $0.myPlaylistsParameters }
    }
    public var pauseCalled: Bool { state.withValue { $0.pauseCalled } }
    public var playCalled: Bool { state.withValue { $0.playCalled } }

    // MARK: - Service Storage

    private struct Services {
        var usersService: UsersAPI?
        var albumsService: AlbumsAPI?
        var tracksService: TracksAPI?
        var artistsService: ArtistsAPI?
        var searchService: SearchAPI?
        var playlistsService: PlaylistsAPI?
        var playerService: PlayerAPI?
    }

    private let services = LockIsolated(Services())

    public init(playlistsHref: URL = URL(string: "https://api.spotify.com/v1/me/playlists")!) {
        self.state = LockIsolated(MockState(playlistsHref: playlistsHref))
    }

    // MARK: - Reset

    /// Reset all mock data and call tracking.
    public func reset() {
        state.withValue { $0.reset() }
    }

    // MARK: - Configuration Builder

    /// Configure mock data in a type-safe, fluent manner.
    ///
    /// This builder method allows you to chain configuration calls and provides
    /// compile-time safety for test setup. Only provided values are updated.
    ///
    /// Example:
    /// ```swift
    /// let mock = MockSpotifyClient()
    ///     .configured(
    ///         profile: SpotifyTestFixtures.currentUserProfile(),
    ///         album: myTestAlbum
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - profile: Mock data for current user profile requests
    ///   - album: Mock data for album requests
    ///   - track: Mock data for track requests
    ///   - artist: Mock data for artist requests
    ///   - searchResult: Mock data for search requests
    ///   - playlist: Mock data for playlist requests
    ///   - playlists: Mock data for playlists collection
    ///   - playlistsTotal: Total count for playlists pagination
    ///   - playlistsHref: Base URL for playlists pagination
    ///   - playbackState: Mock data for playback state requests
    ///   - error: Mock error to throw from all requests
    /// - Returns: Self for method chaining
    @discardableResult
    public func configured(
        profile: CurrentUserProfile? = nil,
        album: Album? = nil,
        track: Track? = nil,
        playlist: Playlist? = nil,
        playlists: [SimplifiedPlaylist]? = nil,
        playlistsTotal: Int? = nil,
        playlistsHref: URL? = nil,
        artist: Artist? = nil,
        searchResult: SearchResults? = nil,
        playbackState: PlaybackState? = nil,
        error: Error? = nil
    ) -> Self {
        state.withValue { state in
            if let profile { state.mockProfile = profile }
            if let album { state.mockAlbum = album }
            if let track { state.mockTrack = track }
            if let playlist { state.mockPlaylist = playlist }
            if let playlists { state.mockPlaylists = playlists }
            if let playlistsTotal { state.mockPlaylistsTotal = playlistsTotal }
            if let playlistsHref { state.mockPlaylistsHref = playlistsHref }
            if let artist { state.mockArtist = artist }
            if let searchResult { state.mockSearchResult = searchResult }
            if let playbackState { state.mockPlaybackState = playbackState }
            if let error { state.mockError = error }
        }
        return self
    }

    // MARK: - Helpers

    fileprivate func resolve<T>(_ value: T?, label: String) throws -> T {
        guard let value else {
            throw MockError.noMockData(label)
        }
        return value
    }

    /// Helper to execute a mock response with automatic error checking and data resolution.
    ///
    /// This reduces boilerplate in mock API implementations by handling the common pattern of:
    /// 1. Setting a call tracking flag
    /// 2. Checking for mock errors
    /// 3. Resolving optional mock data
    ///
    /// - Parameters:
    ///   - body: A closure that receives mutable state, sets flags, and returns optional data
    ///   - label: A label for error messages if data is nil
    /// - Returns: The resolved mock data
    /// - Throws: MockError if data is nil, or the configured mockError if set
    fileprivate func mockResponse<T>(
        _ body: (inout MockState) -> T?,
        label: String
    ) throws -> T {
        try state.withValue { state in
            let data = body(&state)
            if let error = state.mockError { throw error }
            return try resolve(data, label: label)
        }
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
                ? SpotifyTestFixtures.makePageURL(
                    base: state.mockPlaylistsHref,
                    limit: limit,
                    offset: nextOffset
                )
                : nil
            let previousOffset = max(offset - limit, 0)
            let previousURL =
                offset > 0
                ? SpotifyTestFixtures.makePageURL(
                    base: state.mockPlaylistsHref,
                    limit: limit,
                    offset: previousOffset
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

    // MARK: - Private API Implementations

    private final class UsersAPI: SpotifyUsersAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func me() async throws -> CurrentUserProfile {
            try client.mockResponse(
                { state in
                    state.getUsersCalled = true
                    return state.mockProfile
                }, label: "mockProfile")
        }

        func topArtists(
            timeRange: TimeRange,
            limit: Int,
            offset: Int
        ) async throws -> Page<Artist> {
            try client.mockResponse(
                { state in
                    state.topArtistsCalled = true
                    state.topArtistsParameters.append(
                        (range: timeRange, limit: limit, offset: offset))
                    return state.mockTopArtists
                }, label: "mockTopArtists")
        }

        func topTracks(
            timeRange: TimeRange,
            limit: Int,
            offset: Int
        ) async throws -> Page<Track> {
            try client.mockResponse(
                { state in
                    state.topTracksCalled = true
                    state.topTracksParameters.append(
                        (range: timeRange, limit: limit, offset: offset))
                    return state.mockTopTracks
                }, label: "mockTopTracks")
        }
    }

    private final class AlbumsAPI: SpotifyAlbumsAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Album {
            try client.mockResponse(
                { state in
                    state.getAlbumCalled = true
                    return state.mockAlbum
                }, label: "mockAlbum")
        }
    }

    private final class TracksAPI: SpotifyTracksAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Track {
            try client.mockResponse(
                { state in
                    state.getTrackCalled = true
                    return state.mockTrack
                }, label: "mockTrack")
        }
    }

    private final class ArtistsAPI: SpotifyArtistsAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Artist {
            try client.mockResponse(
                { state in
                    state.getArtistCalled = true
                    return state.mockArtist
                }, label: "mockArtist")
        }
    }

    private final class SearchAPI: SpotifySearchAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func search(
            query: String,
            types: Set<SearchType>,
            limit: Int,
            offset: Int
        ) async throws -> SearchResults {
            try client.mockResponse(
                { state in
                    state.searchCalled = true
                    state.searchParameters.append((query, types, limit, offset))
                    return state.mockSearchResult
                }, label: "mockSearchResult")
        }
    }

    private final class PlaylistsAPI: SpotifyPlaylistsAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Playlist {
            try client.mockResponse(
                { state in
                    state.getPlaylistCalled = true
                    return state.mockPlaylist
                }, label: "mockPlaylist")
        }

        func myPlaylists(limit: Int, offset: Int) async throws -> Page<SimplifiedPlaylist> {
            try withMockState { state in
                state.myPlaylistsCalled = true
                state.myPlaylistsParameters.append((limit: limit, offset: offset))
                if let error = state.mockError { throw error }
            }
            return client.makePlaylistsPage(limit: max(0, limit), offset: max(0, offset))
        }
    }

    private final class PlayerAPI: SpotifyPlayerAPI, MockAPIBase, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func pause(deviceID: String?) async throws {
            try withMockState { state in
                state.pauseCalled = true
                if let error = state.mockError { throw error }
            }
        }

        func resume(deviceID: String?) async throws {
            try withMockState { state in
                state.playCalled = true
                if let error = state.mockError { throw error }
            }
        }

        func state(
            market: String?,
            additionalTypes: Set<AdditionalItemType>?
        ) async throws -> PlaybackState? {
            try withMockState { state in
                if let error = state.mockError { throw error }
                return state.mockPlaybackState
            }
        }

        func recentlyPlayed(
            limit: Int,
            after: Date?,
            before: Date?
        ) async throws -> CursorBasedPage<PlayHistoryItem> {
            try client.mockResponse(
                { state in
                    state.recentlyPlayedCalled = true
                    state.recentlyPlayedParameters.append(
                        (limit: limit, after: after, before: before))
                    return state.mockRecentlyPlayed
                }, label: "mockRecentlyPlayed")
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
    var mockSearchResult: SearchResults?
    var mockPlaybackState: PlaybackState?
    var mockTopArtists: Page<Artist>?
    var mockTopTracks: Page<Track>?
    var mockRecentlyPlayed: CursorBasedPage<PlayHistoryItem>?
    var mockError: Error?

    var getUsersCalled = false
    var getAlbumCalled = false
    var getTrackCalled = false
    var getArtistCalled = false
    var searchCalled = false
    var searchParameters: [(query: String, types: Set<SearchType>, limit: Int, offset: Int)] = []
    var getPlaylistCalled = false
    var myPlaylistsCalled = false
    var myPlaylistsParameters: [(limit: Int, offset: Int)] = []
    var pauseCalled = false
    var playCalled = false
    var topArtistsCalled = false
    var topArtistsParameters: [(range: TimeRange, limit: Int, offset: Int)] = []
    var topTracksCalled = false
    var topTracksParameters: [(range: TimeRange, limit: Int, offset: Int)] = []
    var recentlyPlayedCalled = false
    var recentlyPlayedParameters: [(limit: Int, after: Date?, before: Date?)] = []

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

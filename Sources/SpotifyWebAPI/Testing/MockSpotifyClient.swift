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
    
    // MARK: - Mock Data
    
    public var mockProfile: CurrentUserProfile?
    public var mockAlbum: Album?
    public var mockTrack: Track?
    public var mockPlaylist: Playlist?
    public var mockPlaylists: [SimplifiedPlaylist]
    public var mockPlaylistsTotal: Int?
    public var mockPlaylistsHref: URL
    public var mockArtist: Artist?
    public var mockPlaybackState: PlaybackState?
    public var mockError: Error?

    // MARK: - Protocol Surfaces

    public var usersAPI: any SpotifyUsersAPI { usersService }
    public var albumsAPI: any SpotifyAlbumsAPI { albumsService }
    public var tracksAPI: any SpotifyTracksAPI { tracksService }
    public var playlistsAPI: any SpotifyPlaylistsAPI { playlistsService }
    public var playerAPI: any SpotifyPlayerAPI { playerService }
    
    // MARK: - Call Tracking
    
    public private(set) var getUsersCalled = false
    public private(set) var getAlbumCalled = false
    public private(set) var getTrackCalled = false
    public private(set) var getPlaylistCalled = false
    public private(set) var myPlaylistsCalled = false
    public private(set) var myPlaylistsParameters: [(limit: Int, offset: Int)] = []
    public private(set) var pauseCalled = false
    public private(set) var playCalled = false

    private lazy var usersService = UsersAPI(client: self)
    private lazy var albumsService = AlbumsAPI(client: self)
    private lazy var tracksService = TracksAPI(client: self)
    private lazy var playlistsService = PlaylistsAPI(client: self)
    private lazy var playerService = PlayerAPI(client: self)
    
    private let defaultPlaylistsHref: URL
    
    public init(playlistsHref: URL = URL(string: "https://api.spotify.com/v1/me/playlists")!) {
        self.mockPlaylists = []
        self.mockPlaylistsHref = playlistsHref
        self.defaultPlaylistsHref = playlistsHref
    }
    
    // MARK: - Reset
    
    /// Reset all mock data and call tracking.
    public func reset() {
        mockProfile = nil
        mockAlbum = nil
        mockTrack = nil
        mockPlaylist = nil
        mockPlaylists = []
        mockPlaylistsTotal = nil
        mockPlaylistsHref = defaultPlaylistsHref
        mockArtist = nil
        mockPlaybackState = nil
        mockError = nil
        
        getUsersCalled = false
        getAlbumCalled = false
        getTrackCalled = false
        getPlaylistCalled = false
        myPlaylistsCalled = false
        myPlaylistsParameters = []
        pauseCalled = false
        playCalled = false
    }
    
    // MARK: - Helpers

    fileprivate func resolve<T>(_ value: T?, label: String) throws -> T {
        guard let value else {
            throw MockError.noMockData(label)
        }
        return value
    }

    fileprivate func makePlaylistsPage(limit: Int, offset: Int) -> Page<SimplifiedPlaylist> {
        let total = mockPlaylistsTotal ?? mockPlaylists.count
        let items = Array(
            mockPlaylists
                .dropFirst(min(offset, mockPlaylists.count))
                .prefix(max(limit, 0))
        )
        let nextOffset = offset + limit
        let nextURL = nextOffset < total ? makePageURL(limit: limit, offset: nextOffset) : nil
        let previousOffset = max(offset - limit, 0)
        let previousURL = offset > 0 ? makePageURL(limit: limit, offset: previousOffset) : nil
        
        return Page(
            href: mockPlaylistsHref,
            items: items,
            limit: limit,
            next: nextURL,
            offset: offset,
            previous: previousURL,
            total: total
        )
    }

    private func makePageURL(limit: Int, offset: Int) -> URL? {
        guard limit > 0 else { return nil }
        var components = URLComponents(url: mockPlaylistsHref, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems?.filter { $0.name != "limit" && $0.name != "offset" } ?? []
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
            client.getUsersCalled = true
            if let error = client.mockError { throw error }
            return try client.resolve(client.mockProfile, label: "mockProfile")
        }
    }

    private final class AlbumsAPI: SpotifyAlbumsAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Album {
            client.getAlbumCalled = true
            if let error = client.mockError { throw error }
            return try client.resolve(client.mockAlbum, label: "mockAlbum")
        }
    }

    private final class TracksAPI: SpotifyTracksAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Track {
            client.getTrackCalled = true
            if let error = client.mockError { throw error }
            return try client.resolve(client.mockTrack, label: "mockTrack")
        }
    }

    private final class PlaylistsAPI: SpotifyPlaylistsAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func get(_ id: String) async throws -> Playlist {
            client.getPlaylistCalled = true
            if let error = client.mockError { throw error }
            return try client.resolve(client.mockPlaylist, label: "mockPlaylist")
        }

        func myPlaylists(limit: Int, offset: Int) async throws -> Page<SimplifiedPlaylist> {
            client.myPlaylistsCalled = true
            client.myPlaylistsParameters.append((limit: limit, offset: offset))
            if let error = client.mockError { throw error }
            return client.makePlaylistsPage(limit: max(0, limit), offset: max(0, offset))
        }
    }

    private final class PlayerAPI: SpotifyPlayerAPI, @unchecked Sendable {
        unowned let client: MockSpotifyClient

        init(client: MockSpotifyClient) {
            self.client = client
        }

        func pause(deviceID: String?) async throws {
            client.pauseCalled = true
            if let error = client.mockError { throw error }
        }

        func resume(deviceID: String?) async throws {
            client.playCalled = true
            if let error = client.mockError { throw error }
        }

        func state(
            market: String?,
            additionalTypes: Set<AdditionalItemType>?
        ) async throws -> PlaybackState? {
            if let error = client.mockError { throw error }
            return client.mockPlaybackState
        }
    }
}

// MARK: - Mock Error

public enum MockError: Error, Equatable {
    case noMockData(String)
}

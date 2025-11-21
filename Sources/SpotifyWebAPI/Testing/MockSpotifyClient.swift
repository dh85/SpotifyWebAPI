import Foundation

/// A mock Spotify client for testing consumer code.
///
/// Use this in your tests to avoid making real API calls:
///
/// ```swift
/// let mock = MockSpotifyClient()
/// mock.mockProfile = CurrentUserProfile(id: "test", displayName: "Test User", ...)
///
/// // Your code under test
/// let viewModel = MyViewModel(client: mock)
/// await viewModel.loadProfile()
///
/// XCTAssertEqual(viewModel.userName, "Test User")
/// ```
public final class MockSpotifyClient: @unchecked Sendable {
    
    // MARK: - Mock Data
    
    public var mockProfile: CurrentUserProfile?
    public var mockAlbum: Album?
    public var mockTrack: Track?
    public var mockPlaylist: Playlist?
    public var mockPlaylists: [SimplifiedPlaylist] = []
    public var mockArtist: Artist?
    public var mockPlaybackState: PlaybackState?
    public var mockError: Error?
    
    // MARK: - Call Tracking
    
    public private(set) var getUsersCalled = false
    public private(set) var getAlbumCalled = false
    public private(set) var getTrackCalled = false
    public private(set) var getPlaylistCalled = false
    public private(set) var pauseCalled = false
    public private(set) var playCalled = false
    
    public init() {}
    
    // MARK: - Reset
    
    /// Reset all mock data and call tracking.
    public func reset() {
        mockProfile = nil
        mockAlbum = nil
        mockTrack = nil
        mockPlaylist = nil
        mockPlaylists = []
        mockArtist = nil
        mockPlaybackState = nil
        mockError = nil
        
        getUsersCalled = false
        getAlbumCalled = false
        getTrackCalled = false
        getPlaylistCalled = false
        pauseCalled = false
        playCalled = false
    }
    
    // MARK: - Mock Methods
    
    public func me() async throws -> CurrentUserProfile {
        getUsersCalled = true
        if let error = mockError { throw error }
        guard let profile = mockProfile else {
            throw MockError.noMockData("mockProfile")
        }
        return profile
    }
    
    public func getAlbum(_ id: String) async throws -> Album {
        getAlbumCalled = true
        if let error = mockError { throw error }
        guard let album = mockAlbum else {
            throw MockError.noMockData("mockAlbum")
        }
        return album
    }
    
    public func getTrack(_ id: String) async throws -> Track {
        getTrackCalled = true
        if let error = mockError { throw error }
        guard let track = mockTrack else {
            throw MockError.noMockData("mockTrack")
        }
        return track
    }
    
    public func getPlaylist(_ id: String) async throws -> Playlist {
        getPlaylistCalled = true
        if let error = mockError { throw error }
        guard let playlist = mockPlaylist else {
            throw MockError.noMockData("mockPlaylist")
        }
        return playlist
    }
    
    public func myPlaylists() async throws -> [SimplifiedPlaylist] {
        if let error = mockError { throw error }
        return mockPlaylists
    }
    
    public func pause() async throws {
        pauseCalled = true
        if let error = mockError { throw error }
    }
    
    public func play() async throws {
        playCalled = true
        if let error = mockError { throw error }
    }
    
    public func playbackState() async throws -> PlaybackState? {
        if let error = mockError { throw error }
        return mockPlaybackState
    }
}

// MARK: - Mock Error

public enum MockError: Error, Equatable {
    case noMockData(String)
}

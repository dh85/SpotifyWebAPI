import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("MockSpotifyClient Comprehensive Tests")
struct MockSpotifyClientComprehensiveTests {
    
    // MARK: - Album Tests
    
    @Test("getAlbum returns mock album")
    func getAlbumReturnsMockAlbum() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("album_full")
        let album: Album = try decodeModel(from: data)
        mock.mockAlbum = album
        
        let result = try await mock.albums.get("test-id")
        
        #expect(result.id == album.id)
        #expect(mock.getAlbumCalled == true)
    }
    
    @Test("getAlbum throws when no mock data")
    func getAlbumThrowsWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        await #expect(throws: MockError.noMockData("mockAlbum")) {
            _ = try await mock.albums.get("test-id")
        }
        #expect(mock.getAlbumCalled == true)
    }
    
    @Test("getAlbum throws custom error")
    func getAlbumThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.albums.get("test-id")
        }
        #expect(mock.getAlbumCalled == true)
    }
    
    // MARK: - Track Tests
    
    @Test("getTrack returns mock track")
    func getTrackReturnsMockTrack() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("track_full")
        let track: Track = try decodeModel(from: data)
        mock.mockTrack = track
        
        let result = try await mock.tracks.get("test-id")
        
        #expect(result.id == track.id)
        #expect(mock.getTrackCalled == true)
    }
    
    @Test("getTrack throws when no mock data")
    func getTrackThrowsWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        await #expect(throws: MockError.noMockData("mockTrack")) {
            _ = try await mock.tracks.get("test-id")
        }
        #expect(mock.getTrackCalled == true)
    }
    
    @Test("getTrack throws custom error")
    func getTrackThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.tracks.get("test-id")
        }
        #expect(mock.getTrackCalled == true)
    }
    
    // MARK: - Playlist Tests
    
    @Test("getPlaylist returns mock playlist")
    func getPlaylistReturnsMockPlaylist() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("playlist_full")
        let playlist: Playlist = try decodeModel(from: data)
        mock.mockPlaylist = playlist
        
        let result = try await mock.playlists.get("test-id")
        
        #expect(result.id == playlist.id)
        #expect(mock.getPlaylistCalled == true)
    }
    
    @Test("getPlaylist throws when no mock data")
    func getPlaylistThrowsWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        await #expect(throws: MockError.noMockData("mockPlaylist")) {
            _ = try await mock.playlists.get("test-id")
        }
        #expect(mock.getPlaylistCalled == true)
    }
    
    @Test("getPlaylist throws custom error")
    func getPlaylistThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.playlists.get("test-id")
        }
        #expect(mock.getPlaylistCalled == true)
    }
    
    @Test("myPlaylists returns mock playlists")
    func myPlaylistsReturnsMockPlaylists() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("playlists_user")
        let playlistsPage: Page<SimplifiedPlaylist> = try decodeModel(from: data)
        mock.mockPlaylists = playlistsPage.items
        mock.mockPlaylistsTotal = playlistsPage.total
        mock.mockPlaylistsHref = playlistsPage.href
        
        let result = try await mock.playlists.myPlaylists(
            limit: playlistsPage.limit,
            offset: playlistsPage.offset
        )
        
        #expect(result.items == playlistsPage.items)
        #expect(result.total == playlistsPage.total)
        #expect(mock.myPlaylistsCalled == true)
    }
    
    @Test("myPlaylists throws custom error")
    func myPlaylistsThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.playlists.myPlaylists(limit: 20, offset: 0)
        }
    }
    
    // MARK: - Playback Tests
    
    @Test("playbackState returns mock state")
    func playbackStateReturnsMockState() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("playback_state")
        let state: PlaybackState = try decodeModel(from: data)
        mock.mockPlaybackState = state
        
        let result = try await mock.player.state()
        
        #expect(result?.isPlaying == state.isPlaying)
    }
    
    @Test("playbackState returns nil when no mock data")
    func playbackStateReturnsNilWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        let result = try await mock.player.state()
        
        #expect(result == nil)
    }
    
    @Test("playbackState throws custom error")
    func playbackStateThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.player.state()
        }
    }
    
    @Test("pause throws custom error")
    func pauseThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            try await mock.player.pause()
        }
        #expect(mock.pauseCalled == true)
    }
    
    @Test("play throws custom error")
    func playThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            try await mock.player.resume()
        }
        #expect(mock.playCalled == true)
    }
    
    // MARK: - Reset Tests
    
    @Test("reset clears all mock data and call tracking")
    func resetClearsAllData() async throws {
        let mock = MockSpotifyClient()
        let defaultHref = mock.mockPlaylistsHref
        
        // Set up all mock data
        let profileData = try TestDataLoader.load("current_user_profile")
        let profile: CurrentUserProfile = try decodeModel(from: profileData)
        mock.mockProfile = profile
        
        let albumData = try TestDataLoader.load("album_full")
        let album: Album = try decodeModel(from: albumData)
        mock.mockAlbum = album
        
        let trackData = try TestDataLoader.load("track_full")
        let track: Track = try decodeModel(from: trackData)
        mock.mockTrack = track
        
        let playlistData = try TestDataLoader.load("playlist_full")
        let playlist: Playlist = try decodeModel(from: playlistData)
        mock.mockPlaylist = playlist
        
        let playlistsData = try TestDataLoader.load("playlists_user")
        let playlistsPage: Page<SimplifiedPlaylist> = try decodeModel(from: playlistsData)
        mock.mockPlaylists = playlistsPage.items
        mock.mockPlaylistsHref = URL(string: "https://example.com/custom")!
        _ = try await mock.playlists.myPlaylists()
        
        let stateData = try TestDataLoader.load("playback_state")
        let state: PlaybackState = try decodeModel(from: stateData)
        mock.mockPlaybackState = state
        
        // Make calls to set tracking flags
        _ = try await mock.users.me()
        _ = try await mock.albums.get("test")
        _ = try await mock.tracks.get("test")
        _ = try await mock.playlists.get("test")
        try await mock.player.pause()
        try await mock.player.resume()
        
        // Set error after calls
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        // Verify data is set and calls tracked
        #expect(mock.mockProfile != nil)
        #expect(mock.mockAlbum != nil)
        #expect(mock.mockTrack != nil)
        #expect(mock.mockPlaylist != nil)
        #expect(!mock.mockPlaylists.isEmpty)
        #expect(mock.mockPlaybackState != nil)
        #expect(mock.getUsersCalled == true)
        #expect(mock.getAlbumCalled == true)
        #expect(mock.getTrackCalled == true)
        #expect(mock.getPlaylistCalled == true)
        #expect(mock.myPlaylistsCalled == true)
        #expect(!mock.myPlaylistsParameters.isEmpty)
        #expect(mock.pauseCalled == true)
        #expect(mock.playCalled == true)
        
        // Reset
        mock.reset()
        
        // Verify everything is cleared
        #expect(mock.mockProfile == nil)
        #expect(mock.mockAlbum == nil)
        #expect(mock.mockTrack == nil)
        #expect(mock.mockPlaylist == nil)
        #expect(mock.mockPlaylists.isEmpty)
        #expect(mock.mockPlaylistsTotal == nil)
        #expect(mock.mockPlaylistsHref == defaultHref)
        #expect(mock.mockPlaybackState == nil)
        #expect(mock.getUsersCalled == false)
        #expect(mock.getAlbumCalled == false)
        #expect(mock.getTrackCalled == false)
        #expect(mock.getPlaylistCalled == false)
        #expect(mock.myPlaylistsCalled == false)
        #expect(mock.myPlaylistsParameters.isEmpty)
        #expect(mock.pauseCalled == false)
        #expect(mock.playCalled == false)
    }
    
    // MARK: - MockError Tests
    
    @Test("MockError equality works")
    func mockErrorEquality() {
        let error1 = MockError.noMockData("test")
        let error2 = MockError.noMockData("test")
        let error3 = MockError.noMockData("different")
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}

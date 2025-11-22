import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("MockSpotifyClient Tests")
struct MockSpotifyClientTests {

    @Test("Mock returns profile")
    func mockReturnsProfile() async throws {
        let mock = MockSpotifyClient()
        let profile = SpotifyTestFixtures.currentUserProfile(id: "mockuser")
        mock.mockProfile = profile
        
        let result = try await mock.users.me()
        
        #expect(result == profile)
        #expect(mock.getUsersCalled == true)
    }

    @Test("Mock throws when no data")
    func mockThrowsWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        await #expect(throws: MockError.noMockData("mockProfile")) {
            _ = try await mock.users.me()
        }
    }

    @Test("Mock throws custom error")
    func mockThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.users.me()
        }
    }

    @Test("Mock tracks calls")
    func mockTracksCalls() async throws {
        let mock = MockSpotifyClient()
        
        try await mock.player.pause()
        try await mock.player.resume()
        
        #expect(mock.pauseCalled == true)
        #expect(mock.playCalled == true)
    }

    @Test("Mock reset works")
    func mockReset() async throws {
        let mock = MockSpotifyClient()
        mock.mockProfile = SpotifyTestFixtures.currentUserProfile()
        _ = try await mock.users.me()
        
        mock.reset()
        
        #expect(mock.mockProfile == nil)
        #expect(mock.getUsersCalled == false)
    }

    @Test("Mock returns empty playlists")
    func mockReturnsEmptyPlaylists() async throws {
        let mock = MockSpotifyClient()
        
        let playlists = try await mock.playlists.myPlaylists()
        
        #expect(playlists.items.isEmpty)
        #expect(playlists.limit == 20)
        #expect(mock.myPlaylistsCalled == true)
    }

    @Test("myPlaylists respects limit and offset")
    func myPlaylistsRespectsPagination() async throws {
        let mock = MockSpotifyClient()
        mock.mockPlaylists = [
            SpotifyTestFixtures.simplifiedPlaylist(id: "one", name: "One"),
            SpotifyTestFixtures.simplifiedPlaylist(id: "two", name: "Two"),
            SpotifyTestFixtures.simplifiedPlaylist(id: "three", name: "Three")
        ]
        mock.mockPlaylistsTotal = 10
        
        let page = try await mock.playlists.myPlaylists(limit: 2, offset: 1)
        
        #expect(page.items.map(\.id) == ["two", "three"])
        #expect(page.next?.absoluteString.contains("offset=3") == true)
        #expect(page.previous?.absoluteString.contains("offset=0") == true)
        #expect(mock.myPlaylistsParameters.first?.limit == 2)
        #expect(mock.myPlaylistsParameters.first?.offset == 1)
    }
}

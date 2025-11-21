import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("MockSpotifyClient Tests")
struct MockSpotifyClientTests {

    @Test("Mock returns profile")
    func mockReturnsProfile() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("current_user_profile")
        let profile: CurrentUserProfile = try decodeModel(from: data)
        mock.mockProfile = profile
        
        let result = try await mock.me()
        
        #expect(result.id == "mockuser")
        #expect(mock.getUsersCalled == true)
    }

    @Test("Mock throws when no data")
    func mockThrowsWhenNoData() async throws {
        let mock = MockSpotifyClient()
        
        await #expect(throws: MockError.noMockData("mockProfile")) {
            _ = try await mock.me()
        }
    }

    @Test("Mock throws custom error")
    func mockThrowsCustomError() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await mock.me()
        }
    }

    @Test("Mock tracks calls")
    func mockTracksCalls() async throws {
        let mock = MockSpotifyClient()
        
        try await mock.pause()
        try await mock.play()
        
        #expect(mock.pauseCalled == true)
        #expect(mock.playCalled == true)
    }

    @Test("Mock reset works")
    func mockReset() async throws {
        let mock = MockSpotifyClient()
        let data = try TestDataLoader.load("current_user_profile")
        let profile: CurrentUserProfile = try decodeModel(from: data)
        mock.mockProfile = profile
        _ = try await mock.me()
        
        mock.reset()
        
        #expect(mock.mockProfile == nil)
        #expect(mock.getUsersCalled == false)
    }

    @Test("Mock returns empty playlists")
    func mockReturnsEmptyPlaylists() async throws {
        let mock = MockSpotifyClient()
        
        let playlists = try await mock.myPlaylists()
        
        #expect(playlists.isEmpty)
    }
}

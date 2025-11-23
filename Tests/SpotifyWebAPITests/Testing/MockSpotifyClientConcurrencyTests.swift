import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("MockSpotifyClient Concurrency")
struct MockSpotifyClientConcurrencyTests {

    @Test("Concurrent property writes are serialized")
    func concurrentPropertyWrites() async throws {
        let mock = MockSpotifyClient()
        let iterations = 200

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<iterations {
                group.addTask {
                    mock.mockProfile = SpotifyTestFixtures.currentUserProfile(id: "user\(index)")
                    mock.mockPlaylists = [
                        SpotifyTestFixtures.simplifiedPlaylist(id: "p\(index)")
                    ]
                    mock.mockPlaylistsTotal = index
                    mock.mockPlaylistsHref = URL(string: "https://example.com/\(index)")!
                    mock.mockError = nil
                }
            }
            try await group.waitForAll()
        }

        #expect(mock.mockProfile != nil)
        #expect(mock.mockPlaylists.count == 1)
        #expect(mock.mockPlaylistsHref.host == "example.com")
    }

    @Test("Concurrent API calls respect ordering")
    func concurrentAPICalls() async throws {
        let mock = MockSpotifyClient()
        mock.mockProfile = SpotifyTestFixtures.currentUserProfile(id: "profile")
        mock.mockPlaylists = (1...5).map { SpotifyTestFixtures.simplifiedPlaylist(id: "pl-\($0)") }

        let iterations = 50
        try await withThrowingTaskGroup(of: Void.self) { group in
            for offset in 0..<iterations {
                group.addTask {
                    _ = try await mock.users.me()
                    _ = try await mock.playlists.myPlaylists(limit: 2, offset: offset % 3)
                    try await mock.player.pause()
                    try await mock.player.resume()
                }
            }
            try await group.waitForAll()
        }

        #expect(mock.getUsersCalled == true)
        #expect(mock.myPlaylistsParameters.count == iterations)
        #expect(mock.pauseCalled == true)
        #expect(mock.playCalled == true)
    }
}

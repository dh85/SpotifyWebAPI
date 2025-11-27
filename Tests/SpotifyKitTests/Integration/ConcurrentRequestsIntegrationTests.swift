import Foundation
import Testing

@testable import SpotifyKit

/// Integration tests for concurrent request handling, token refresh, and thread safety.
@Suite("Concurrent Requests Integration Tests")
struct ConcurrentRequestsIntegrationTests {

    // MARK: - Parallel API Calls

    @Test("Multiple concurrent API calls complete successfully")
    func multipleConcurrentAPICallsCompleteSuccessfully() async throws {
        let playlists = (0..<10).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "concurrent-\(index)",
                name: "Concurrent Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(
            profile: SpotifyTestFixtures.currentUserProfile(id: "concurrent-user"),
            playlists: playlists
        )
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Execute 5 concurrent requests to different endpoints
            async let profile1 = client.users.me()
            async let profile2 = client.users.me()
            async let playlists1 = client.playlists.myPlaylists(limit: 5)
            async let playlists2 = client.playlists.myPlaylists(limit: 3, offset: 2)
            async let allPlaylists = client.playlists.allMyPlaylists()

            let (p1, p2, pl1, pl2, all) = try await (
                profile1, profile2, playlists1, playlists2, allPlaylists
            )

            #expect(p1.id == "concurrent-user")
            #expect(p2.id == "concurrent-user")
            #expect(pl1.items.count == 5)
            #expect(pl2.items.count == 3)
            #expect(all.count == 10)
        }
    }

    @Test("Same endpoint called concurrently returns consistent results")
    func sameEndpointCalledConcurrentlyReturnsConsistentResults() async throws {
        let profile = SpotifyTestFixtures.currentUserProfile(
            id: "consistent-user",
            displayName: "Consistency Test",
            email: "consistent@test.com"
        )
        let configuration = SpotifyMockAPIServer.Configuration(profile: profile)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Fetch profile 10 times concurrently
            let profiles = try await withThrowingTaskGroup(of: CurrentUserProfile.self) { group in
                for _ in 0..<10 {
                    group.addTask {
                        try await client.users.me()
                    }
                }

                var results: [CurrentUserProfile] = []
                for try await profile in group {
                    results.append(profile)
                }
                return results
            }

            #expect(profiles.count == 10)
            #expect(profiles.allSatisfy { $0.id == "consistent-user" })
            #expect(profiles.allSatisfy { $0.email == "consistent@test.com" })
        }
    }

    @Test("Concurrent streaming operations work correctly")
    func concurrentStreamingOperationsWorkCorrectly() async throws {
        let playlists = (0..<100).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "stream-\(index)",
                name: "Stream Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Start two streaming operations concurrently
            async let stream1Count = countStreamItems(client: client, maxItems: 25)
            async let stream2Count = countStreamItems(client: client, maxItems: 30)

            let (count1, count2) = try await (stream1Count, stream2Count)

            #expect(count1 == 25)
            #expect(count2 == 30)
        }
    }

    @Test("Concurrent pagination with different limits")
    func concurrentPaginationWithDifferentLimits() async throws {
        let playlists = (0..<50).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "page-\(index)",
                name: "Page Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Fetch pages with different limits concurrently
            async let page10 = client.playlists.myPlaylists(limit: 10)
            async let page20 = client.playlists.myPlaylists(limit: 20)
            async let page50 = client.playlists.myPlaylists(limit: 50)

            let (p10, p20, p50) = try await (page10, page20, page50)

            #expect(p10.items.count == 10)
            #expect(p20.items.count == 20)
            #expect(p50.items.count == 50)
            #expect(p10.total == 50)
            #expect(p20.total == 50)
            #expect(p50.total == 50)
        }
    }

    // MARK: - Thread Safety

    @Test("Concurrent writes and reads to playlist are safe")
    func concurrentWritesAndReadsToPlaylistAreSafe() async throws {
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "concurrent-writes",
            name: "Concurrent Write Test",
            totalTracks: 0
        )
        let configuration = SpotifyMockAPIServer.Configuration(
            playlists: [playlist],
            playlistTracks: [playlist.id: []]
        )
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Perform concurrent writes
            let snapshots = try await withThrowingTaskGroup(of: String.self) { group in
                for i in 0..<5 {
                    group.addTask {
                        try await client.playlists.add(
                            to: "concurrent-writes",
                            uris: ["spotify:track:concurrent\(i)"]
                        )
                    }
                }

                var results: [String] = []
                for try await snapshot in group {
                    results.append(snapshot)
                }
                return results
            }

            #expect(snapshots.count == 5)
            #expect(snapshots.allSatisfy { !$0.isEmpty })
        }
    }

    @Test("Concurrent client configuration access is thread-safe")
    func concurrentClientConfigurationAccessIsThreadSafe() async throws {
        let server = SpotifyMockAPIServer()

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Access configuration from multiple concurrent tasks
            let timeouts = await withTaskGroup(of: TimeInterval.self) { group in
                for _ in 0..<20 {
                    group.addTask {
                        await client.configuration.requestTimeout
                    }
                }

                var results: [TimeInterval] = []
                for await timeout in group {
                    results.append(timeout)
                }
                return results
            }

            #expect(timeouts.count == 20)
            #expect(timeouts.allSatisfy { $0 == timeouts.first })
        }
    }

    // MARK: - Helpers

    private func makeUserClient(for info: SpotifyMockAPIServer.RunningServer)
        -> SpotifyClient<UserAuthCapability>
    {
        let authenticator = SpotifyClientCredentialsAuthenticator(
            config: .clientCredentials(
                clientID: "concurrent-test-client",
                clientSecret: "concurrent-test-secret",
                scopes: [.userReadEmail, .playlistReadPrivate, .playlistModifyPublic],
                tokenEndpoint: info.tokenEndpoint
            ),
            httpClient: URLSessionHTTPClient()
        )

        return SpotifyClient<UserAuthCapability>(
            backend: authenticator,
            httpClient: URLSessionHTTPClient(),
            configuration: SpotifyClientConfiguration(
                apiBaseURL: info.apiBaseURL
            )
        )
    }

    private func countStreamItems(client: SpotifyClient<UserAuthCapability>, maxItems: Int)
        async throws -> Int
    {
        var count = 0
        for try await _ in client.playlists.streamMyPlaylists(maxItems: maxItems) {
            count += 1
        }
        return count
    }
}

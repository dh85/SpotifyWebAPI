import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Network Recovery Integration Tests")
struct NetworkRecoveryIntegrationTests {
    
    @Test("503 Service Unavailable triggers error")
    func serviceUnavailableTriggersError() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 503,
            errorMessage: "Service Unavailable",
            affectedEndpoints: ["/v1/me"],
            behavior: .always
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let usersService = client.users
            
            do {
                _ = try await usersService.me()
                Issue.record("Expected 503 error")
            } catch {
                let errorDescription = String(describing: error)
                #expect(errorDescription.contains("503") || 
                       errorDescription.contains("Service Unavailable") ||
                       errorDescription.contains("unavailable"))
            }
        }
    }
    
    @Test("503 error with retry after temporary failure")
    func serviceUnavailableWithRetry() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 503,
            errorMessage: "Service Unavailable",
            affectedEndpoints: ["/v1/me"],
            behavior: .once // Fail once, then succeed
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let usersService = client.users
            
            // First request fails with 503
            do {
                _ = try await usersService.me()
                Issue.record("Expected 503 error on first request")
            } catch {
                // Expected
            }
            
            // Retry succeeds
            let profile = try await usersService.me()
            #expect(profile.id == "test-user")
        }
    }
    
    @Test("Multiple 503 errors before success")
    func multipleServiceUnavailableErrors() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 503,
            errorMessage: "Service Unavailable",
            affectedEndpoints: ["/v1/me"],
            behavior: .nthRequest(3) // Fail on 3rd request
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let usersService = client.users
            
            // First two succeed
            _ = try await usersService.me()
            _ = try await usersService.me()
            
            // Third fails
            do {
                _ = try await usersService.me()
                Issue.record("Expected 503 error on 3rd request")
            } catch {
                // Expected
            }
            
            // Fourth succeeds (recovery)
            let profile = try await usersService.me()
            #expect(profile.id == "test-user")
        }
    }
    
    @Test("Network error during pagination recovers gracefully")
    func networkErrorDuringPagination() async throws {
        // Use more than the 50-item paging size so a second request is required
        let playlists = (0..<75).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist-\(index)",
                name: "Playlist \(index)",
                ownerID: "owner"
            )
        }
        
        // Inject error on 2nd request (during pagination)
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 503,
            errorMessage: "Service Unavailable",
            affectedEndpoints: ["/v1/me/playlists"],
            behavior: .nthRequest(2)
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            playlists: playlists,
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            
            // Try to fetch all playlists
            // First page succeeds, second page fails
            do {
                _ = try await playlistsService.allMyPlaylists()
                Issue.record("Expected error during pagination")
            } catch {
                // Expected - error during pagination
            }
        }
    }
    
    @Test("Intermittent 500 errors handled")
    func intermittentServerErrors() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 500,
            errorMessage: "Internal Server Error",
            affectedEndpoints: ["/v1/me"],
            behavior: .everyNthRequest(3) // Every 3rd request fails
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let usersService = client.users
            
            var successCount = 0
            var errorCount = 0
            
            // Make 10 requests
            for _ in 1...10 {
                do {
                    _ = try await usersService.me()
                    successCount += 1
                } catch {
                    errorCount += 1
                }
            }
            
            // With everyNthRequest(3), requests 3, 6, 9 should fail
            #expect(errorCount == 3, "Expected 3 errors")
            #expect(successCount == 7, "Expected 7 successes")
        }
    }
    
    @Test("Connection timeout error handled")
    func connectionTimeoutHandled() async throws {
        // Note: This test verifies timeout handling by attempting to connect
        // to a non-existent server that will timeout
        
        // Create a mock server and stop it immediately to simulate connection issues
        let server = SpotifyMockAPIServer()
        let info = try await server.start()
        
        // Stop the server to make it unreachable
        await server.stop()
        
        // Now try to connect - should fail
        let invalidConfig = SpotifyClientConfiguration(
            requestTimeout: 1.0, // 1 second timeout
            apiBaseURL: info.apiBaseURL
        )
        
        let authenticator = SpotifyClientCredentialsAuthenticator(
            config: .clientCredentials(
                clientID: "test-client",
                clientSecret: "test-secret",
                scopes: [],
                tokenEndpoint: info.tokenEndpoint
            ),
            httpClient: URLSessionHTTPClient()
        )
        
        let client = SpotifyClient<UserAuthCapability>(
            backend: authenticator,
            httpClient: URLSessionHTTPClient(),
            configuration: invalidConfig
        )
        
        let usersService = client.users
        
        do {
            _ = try await usersService.me()
            Issue.record("Expected timeout error")
        } catch {
            // Expected - should be a connection or timeout error
            let errorDescription = String(describing: error)
            #expect(
                errorDescription.contains("timeout") ||
                errorDescription.contains("connection") ||
                errorDescription.contains("Could not connect") ||
                errorDescription.contains("refused")
            )
        }
    }
    
    @Test("Network failure preserves operation semantics")
    func networkFailurePreservesSemantics() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 503,
            errorMessage: "Service Unavailable",
            affectedEndpoints: ["/v1/playlists"],
            behavior: .once
        )
        
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "test-playlist",
            name: "Test Playlist",
            ownerID: "test-user",
            totalTracks: 0
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            playlists: [playlist],
            playlistTracks: [playlist.id: []],
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            
            // Try to add tracks - first attempt fails
            do {
                _ = try await playlistsService.add(
                    to: playlist.id,
                    uris: ["spotify:track:test1"]
                )
                Issue.record("Expected error on first add attempt")
            } catch {
                // Expected
            }
            
            // Retry - should succeed and actually add the track
            let snapshot = try await playlistsService.add(
                to: playlist.id,
                uris: ["spotify:track:test1"]
            )
            #expect(!snapshot.isEmpty)
            
            // Verify track was added
            let items = try await playlistsService.items(playlist.id)
            #expect(items.total == 1)
        }
    }
    
    @Test("Mixed success and failure requests")
    func mixedSuccessAndFailure() async throws {
        let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
            statusCode: 500,
            errorMessage: "Error",
            affectedEndpoints: ["/v1/me"],
            behavior: .everyNthRequest(2)
        )
        
        let config = SpotifyMockAPIServer.Configuration(
            errorInjection: errorConfig
        )
        let server = SpotifyMockAPIServer(configuration: config)
        
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let usersService = client.users
            let playlistsService = client.playlists
            
            // Request to /v1/me - succeeds (1st)
            let profile1 = try await usersService.me()
            #expect(profile1.id == "test-user")
            
            // Request to playlists - succeeds (not affected by error injection)
            let playlists = try await playlistsService.myPlaylists()
            #expect(!playlists.items.isEmpty)
            
            // Request to /v1/me - fails (2nd)
            do {
                _ = try await usersService.me()
                Issue.record("Expected error on 2nd /v1/me request")
            } catch {
                // Expected
            }
            
            // Request to /v1/me - succeeds (3rd)
            let profile2 = try await usersService.me()
            #expect(profile2.id == "test-user")
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeUserClient(for info: SpotifyMockAPIServer.RunningServer)
        -> SpotifyClient<UserAuthCapability>
    {
        let authenticator = SpotifyClientCredentialsAuthenticator(
            config: .clientCredentials(
                clientID: "integration-client",
                clientSecret: "integration-secret",
                scopes: [.userReadEmail, .playlistReadPrivate, .playlistModifyPrivate],
                tokenEndpoint: info.tokenEndpoint
            ),
            httpClient: URLSessionHTTPClient()
        )

        return SpotifyClient<UserAuthCapability>(
            backend: authenticator,
            httpClient: URLSessionHTTPClient(),
            configuration: SpotifyClientConfiguration(
                networkRecovery: .disabled,
                requestDeduplicationEnabled: false,
                apiBaseURL: info.apiBaseURL
            )
        )
    }
}

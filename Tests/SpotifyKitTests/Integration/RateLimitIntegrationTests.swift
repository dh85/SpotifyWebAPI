import Foundation
import Testing

@testable import SpotifyKit

@Suite("Rate Limit Integration Tests")
struct RateLimitIntegrationTests {

  @Test("Rate limit returns 429 with Retry-After header")
  func rateLimitReturns429WithRetryAfter() async throws {
    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 3,
      windowDuration: 10,
      retryAfterSeconds: 2
    )

    let config = SpotifyMockAPIServer.Configuration(
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // First 3 requests should succeed
      for i in 1...3 {
        let profile = try await usersService.me()
        #expect(profile.id == "testUser", "Request \(i) should succeed")
      }

      // 4th request should hit rate limit
      do {
        _ = try await usersService.me()
        Issue.record("Expected rate limit error")
      } catch {
        // Verify it's a rate limit error (429)
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("429") || errorDescription.contains("rate"))
      }
    }
  }

  @Test("Rate limit window resets after duration")
  func rateLimitWindowResetsAfterDuration() async throws {
    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 2,
      windowDuration: 2,  // 2 second window
      retryAfterSeconds: 1
    )

    let config = SpotifyMockAPIServer.Configuration(
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // Use up the rate limit
      _ = try await usersService.me()
      _ = try await usersService.me()

      // This should fail
      do {
        _ = try await usersService.me()
        Issue.record("Expected rate limit error")
      } catch {
        // Expected rate limit error
      }

      // Wait for window to reset
      try await Task.sleep(for: .seconds(2.1))

      // Should succeed now
      let profile = try await usersService.me()
      #expect(profile.id == "testUser")
    }
  }

  @Test("Concurrent requests count toward rate limit")
  func concurrentRequestsCountTowardRateLimit() async throws {
    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 5,
      windowDuration: 10,
      retryAfterSeconds: 1
    )

    let config = SpotifyMockAPIServer.Configuration(
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // Make 5 concurrent requests
      let results = await withTaskGroup(of: Result<CurrentUserProfile, Error>.self) { group in
        for _ in 1...5 {
          group.addTask {
            do {
              let profile = try await usersService.me()
              return .success(profile)
            } catch {
              return .failure(error)
            }
          }
        }

        var collected: [Result<CurrentUserProfile, Error>] = []
        for await result in group {
          collected.append(result)
        }
        return collected
      }

      // All 5 should succeed (at the limit)
      let successCount = results.count {
        if case .success = $0 { return true }
        return false
      }
      #expect(successCount == 5)

      // Next request should fail
      do {
        _ = try await usersService.me()
        Issue.record("Expected rate limit error after concurrent requests")
      } catch {
        // Expected
      }
    }
  }

  @Test("Different endpoints have separate rate limit counters")
  func differentEndpointsHaveSeparateCounters() async throws {
    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 3,
      windowDuration: 10,
      retryAfterSeconds: 1
    )

    let config = SpotifyMockAPIServer.Configuration(
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users
      let playlistsService = client.playlists

      // Use up rate limit on /v1/me
      _ = try await usersService.me()
      _ = try await usersService.me()
      _ = try await usersService.me()

      // /v1/me should be rate limited
      do {
        _ = try await usersService.me()
        Issue.record("Expected rate limit on /v1/me")
      } catch {
        // Expected
      }

      // But /v1/me/playlists should still work (separate counter)
      let playlists = try await playlistsService.myPlaylists(limit: 5)
      #expect(playlists.items.count > 0)
    }
  }

  @Test("Client receives rate limit info in error")
  func clientReceivesRateLimitInfo() async throws {
    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 1,
      windowDuration: 10,
      retryAfterSeconds: 3
    )

    let config = SpotifyMockAPIServer.Configuration(
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // First request succeeds
      _ = try await usersService.me()

      // Second request hits rate limit
      do {
        _ = try await usersService.me()
        Issue.record("Expected rate limit error")
      } catch {
        // Check that error contains retry information
        let errorDescription = String(describing: error)
        #expect(
          errorDescription.contains("429") || errorDescription.contains("rate")
            || errorDescription.contains("retry"))
      }
    }
  }

  @Test("Rate limit applies to pagination requests")
  func rateLimitAppliesToPagination() async throws {
    // Create many playlists to force pagination. With the default
    // page size of 50, 120 items will require 3 requests.
    let playlists = (0..<120).map { index in
      SpotifyTestFixtures.simplifiedPlaylist(
        id: "playlist\(index)",
        name: "Playlist \(index)",
        ownerID: "owner"
      )
    }

    let rateLimitConfig = SpotifyMockAPIServer.RateLimitConfig(
      maxRequestsPerWindow: 2,  // Only allow 2 requests
      windowDuration: 10,
      retryAfterSeconds: 1
    )

    let config = SpotifyMockAPIServer.Configuration(
      playlists: playlists,
      rateLimitConfig: rateLimitConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let playlistsService = client.playlists

      // Try to fetch all playlists (requires multiple pages)
      // 120 items at 50 per page requires 3 requests, but the
      // rate limit only allows 2 requests per window.
      do {
        for try await _ in playlistsService.streamMyPlaylists() { }
        Issue.record("Expected rate limit during pagination")
      } catch {
        // Expected - should hit rate limit during pagination
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("429") || errorDescription.contains("rate"))
      }
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
        requestDeduplicationEnabled: false,
        apiBaseURL: info.apiBaseURL
      )
    )
  }
}

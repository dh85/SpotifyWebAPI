import Foundation
import Testing

@testable import SpotifyKit

/// Integration tests covering complete end-to-end workflows across multiple services.
@Suite("Multi-Service Workflow Integration Tests")
struct MultiServiceWorkflowIntegrationTests {

  @Test("User profile followed by playlists query")
  func userProfileThenPlaylistsQuery() async throws {
    let playlists = (0..<10).map { index in
      SpotifyTestFixtures.simplifiedPlaylist(
        id: "workflow-\(index)",
        name: "Workflow Playlist \(index)",
        ownerID: "workflow-owner"
      )
    }
    let configuration = SpotifyMockAPIServer.Configuration(
      profile: SpotifyTestFixtures.currentUserProfile(id: "workflow-user"),
      playlists: playlists
    )
    let server = SpotifyMockAPIServer(configuration: configuration)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)

      // Step 1: Fetch user profile
      let profile = try await client.users.me()
      #expect(profile.id == "workflow-user")

      // Step 2: Fetch playlists
      let playlistPage = try await client.playlists.myPlaylists(limit: 5)
      #expect(playlistPage.items.count == 5)
      #expect(playlistPage.total == 10)
    }
  }

  @Test("Multiple playlist operations in sequence")
  func multiplePlaylistOperationsInSequence() async throws {
    let playlists = (0..<20).map { index in
      SpotifyTestFixtures.simplifiedPlaylist(
        id: "seq-\(index)",
        name: "Sequential \(index)"
      )
    }
    let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
    let server = SpotifyMockAPIServer(configuration: configuration)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)

      // Multiple operations
      let page1 = try await client.playlists.myPlaylists(limit: 10, offset: 0)
      let page2 = try await client.playlists.myPlaylists(limit: 10, offset: 10)
      let all = try await client.playlists.myPlaylists()

      #expect(page1.items.count == 10)
      #expect(page2.items.count == 10)
      #expect(all.items.count == 20)
      #expect(page1.items.first?.id == "seq-0")
      #expect(page2.items.first?.id == "seq-10")
    }
  }

  @Test("Batch track operations on playlist")
  func batchTrackOperationsOnPlaylist() async throws {
    let playlist = SpotifyTestFixtures.simplifiedPlaylist(
      id: "batch-playlist",
      name: "Batch Operations Test",
      totalTracks: 0
    )
    let configuration = SpotifyMockAPIServer.Configuration(
      playlists: [playlist],
      playlistTracks: [playlist.id: []]
    )
    let server = SpotifyMockAPIServer(configuration: configuration)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)

      // Add tracks
      let trackURIs = (0..<5).map { "spotify:track:track\($0)" }
      let snapshot = try await client.playlists.add(
        to: "batch-playlist",
        uris: trackURIs
      )

      #expect(!snapshot.isEmpty, "Snapshot ID should be returned")

      // Verify tracks were added by fetching playlist items
      let items = try await client.playlists.items("batch-playlist")
      #expect(items.items.count == 5)
    }
  }

  @Test("Concurrent profile fetches remain consistent")
  func concurrentProfileFetchesRemainConsistent() async throws {
    let profile = SpotifyTestFixtures.currentUserProfile(
      id: "concurrent-user",
      displayName: "Concurrent Test User"
    )
    let configuration = SpotifyMockAPIServer.Configuration(profile: profile)
    let server = SpotifyMockAPIServer(configuration: configuration)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)

      // Fetch profile 5 times concurrently
      async let p1 = client.users.me()
      async let p2 = client.users.me()
      async let p3 = client.users.me()
      async let p4 = client.users.me()
      async let p5 = client.users.me()

      let profiles = try await [p1, p2, p3, p4, p5]

      // All should be identical
      #expect(profiles.allSatisfy { $0.id == "concurrent-user" })
      #expect(profiles.allSatisfy { $0.displayName == "Concurrent Test User" })
    }
  }

  @Test("Streaming playlists with early termination")
  func streamingPlaylistsWithEarlyTermination() async throws {
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

      var count = 0
      for try await _ in client.playlists.streamMyPlaylists() {
        count += 1
        if count >= 25 {
          break
        }
      }

      #expect(count == 25, "Should stop after processing 25 playlists")
    }
  }

  @Test("Playlist page streaming processes all pages")
  func playlistPageStreamingProcessesAllPages() async throws {
    let playlists = (0..<75).map { index in
      SpotifyTestFixtures.simplifiedPlaylist(
        id: "page-stream-\(index)",
        name: "Page Stream \(index)"
      )
    }
    let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
    let server = SpotifyMockAPIServer(configuration: configuration)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)

      var pageCount = 0
      var totalItems = 0

      for try await page in client.playlists.streamMyPlaylistPages(maxPages: 2) {
        pageCount += 1
        totalItems += page.items.count
      }

      #expect(pageCount == 2, "Should process 2 pages")
      // With 75 total items and 50 per page (default), we get: page 1 = 50, page 2 = 25
      #expect(totalItems == 75, "Should process all 75 items across 2 pages")
    }
  }

  // MARK: - Helpers

  private func makeUserClient(for info: SpotifyMockAPIServer.RunningServer)
    -> SpotifyClient<UserAuthCapability>
  {
    let authenticator = SpotifyClientCredentialsAuthenticator(
      config: .clientCredentials(
        clientID: "integration-client",
        clientSecret: "integration-secret",
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
}

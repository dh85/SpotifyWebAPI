import Foundation
import Testing

@testable import SpotifyKit

@Suite("IntegrationTests")
struct SpotifyIntegrationTests {

    @Test
    func usersMeEndpointServedByMockAPI() async throws {
        let server = SpotifyMockAPIServer()
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let userService = client.users
            let profile = try await userService.me()
            #expect(profile.id == "testUser")
            #expect(profile.displayName == "Test User")
            #expect(profile.email == "test@example.com")
        }
    }

    @Test
    func myPlaylistsHonorsLimitAndOffset() async throws {
        let server = SpotifyMockAPIServer()
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            let page = try await playlistsService.myPlaylists(limit: 3, offset: 2)

            #expect(page.limit == 3)
            #expect(page.offset == 2)
            #expect(page.total == 10)
            #expect(page.items.map(\.id) == ["playlist2", "playlist3", "playlist4"])
        }
    }

    @Test
    func allMyPlaylistsFetchesEveryPage() async throws {
        let playlists = (0..<75).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "paginated\(index)",
                name: "Paginated #\(index)",
                ownerID: "owner\(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            let fetched = try await playlistsService.allMyPlaylists()

            #expect(fetched.count == playlists.count)
            #expect(fetched.first?.id == playlists.first?.id)
            #expect(fetched.last?.id == playlists.last?.id)
        }
    }

    @Test
    func streamMyPlaylistsRespectsMaxItems() async throws {
        let server = SpotifyMockAPIServer()
        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            var collected: [SimplifiedPlaylist] = []

            for try await playlist in playlistsService.streamMyPlaylists(maxItems: 4) {
                collected.append(playlist)
            }

            #expect(collected.count == 4)
            #expect(
                collected.map(\.id) == ["playlist0", "playlist1", "playlist2", "playlist3"])
        }
    }

    @Test
    func addingTracksUpdatesPlaylistItems() async throws {
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "integrationPlaylist",
            name: "Integration Playlist",
            ownerID: "integrationUser",
            totalTracks: 0
        )
        let configuration = SpotifyMockAPIServer.Configuration(
            playlists: [playlist],
            playlistTracks: [playlist.id: []]
        )
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists
            let playlistID = playlist.id

            let snapshot = try await playlistsService.add(
                to: playlistID,
                uris: [
                    "spotify:track:integrationOne",
                    "spotify:track:integrationTwo",
                ]
            )
            #expect(snapshot == "snapshot-1")

            let page = try await playlistsService.items(playlistID, limit: 10, offset: 0)
            let uris = page.items.compactMap { item -> String? in
                guard case .track(let track)? = item.track else { return nil }
                return track.uri
            }
            #expect(uris == ["spotify:track:integrationOne", "spotify:track:integrationTwo"])
        }
    }

    @Test
    func removingTracksByURIAndPositionUpdatesState() async throws {
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "mutationPlaylist",
            name: "Mutation Playlist",
            ownerID: "integrationUser",
            totalTracks: 3
        )
        let initialTracks = [
            "spotify:track:keepMe",
            "spotify:track:removeMe",
            "spotify:track:leaveMe",
        ]
        let configuration = SpotifyMockAPIServer.Configuration(
            playlists: [playlist],
            playlistTracks: [playlist.id: initialTracks]
        )
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)
            let playlistsService = client.playlists

            let firstSnapshot = try await playlistsService.remove(
                from: playlist.id,
                uris: ["spotify:track:removeMe"]
            )
            #expect(firstSnapshot == "snapshot-1")

            let secondSnapshot = try await playlistsService.remove(
                from: playlist.id,
                positions: [0]
            )
            #expect(secondSnapshot == "snapshot-2")

            let remaining = try await playlistsService.items(playlist.id)
            let uris = remaining.items.compactMap { item -> String? in
                guard case .track(let track)? = item.track else { return nil }
                return track.uri
            }
            #expect(uris == ["spotify:track:leaveMe"])
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
                scopes: [.userReadEmail, .playlistReadPrivate, .playlistModifyPrivate],
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

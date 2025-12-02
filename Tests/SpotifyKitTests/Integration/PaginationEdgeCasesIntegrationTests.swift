import Foundation
import Testing

@testable import SpotifyKit

/// Integration tests for pagination edge cases including empty sets, cancellation, and errors.
@Suite("Pagination Edge Cases Integration Tests")
struct PaginationEdgeCasesIntegrationTests {

    // MARK: - Empty Sets

    @Test("Empty playlist collection returns zero items")
    func emptyPlaylistCollectionReturnsZeroItems() async throws {
        let configuration = SpotifyMockAPIServer.Configuration(playlists: [])
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let page = try await client.playlists.myPlaylists()

            #expect(page.items.isEmpty)
            #expect(page.total == 0)
            #expect(page.next == nil)
            #expect(page.previous == nil)
        }
    }

    @Test("Streaming empty collection completes immediately")
    func streamingEmptyCollectionCompletesImmediately() async throws {
        let configuration = SpotifyMockAPIServer.Configuration(playlists: [])
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            var count = 0
            for try await _ in client.playlists.streamMyPlaylists() {
                count += 1
            }

            #expect(count == 0, "Empty collection should yield no items")
        }
    }

    @Test("Fetch all on empty collection returns empty array")
    func fetchAllOnEmptyCollectionReturnsEmptyArray() async throws {
        let configuration = SpotifyMockAPIServer.Configuration(playlists: [])
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let all = try await client.playlists.allMyPlaylists()

            #expect(all.isEmpty, "Should return empty array for empty collection")
        }
    }

    // MARK: - Single Item

    @Test("Single playlist collection works correctly")
    func singlePlaylistCollectionWorksCorrectly() async throws {
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "singlePlaylist",
            name: "Only Playlist"
        )
        let configuration = SpotifyMockAPIServer.Configuration(playlists: [playlist])
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let page = try await client.playlists.myPlaylists(limit: 10)

            #expect(page.items.count == 1)
            #expect(page.total == 1)
            #expect(page.next == nil)
            #expect(page.items.first?.id == "singlePlaylist")
        }
    }

    // MARK: - Offset Beyond Bounds

    @Test("Offset beyond total returns empty page")
    func offsetBeyondTotalReturnsEmptyPage() async throws {
        let playlists = (0..<10).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let page = try await client.playlists.myPlaylists(limit: 10, offset: 100)

            #expect(page.items.isEmpty, "Offset beyond bounds should return empty page")
            #expect(page.total == 10)
            #expect(page.offset == 100)
            #expect(page.next == nil)
        }
    }

    // MARK: - Large Limit

    @Test("Limit at API max returns available items")
    func limitAtAPIMaxReturnsAvailableItems() async throws {
        let playlists = (0..<5).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            // Use API max limit of 50
            let page = try await client.playlists.myPlaylists(limit: 50)

            #expect(page.items.count == 5, "Should return all available items")
            #expect(page.total == 5)
            #expect(page.next == nil)
        }
    }

    // MARK: - Exact Page Boundaries

    @Test("Exact multiple of page size handles correctly")
    func exactMultipleOfPageSizeHandlesCorrectly() async throws {
        // Create exactly 100 playlists (2 pages of 50 each)
        let playlists = (0..<100).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let all = try await client.playlists.allMyPlaylists()

            #expect(all.count == 100, "Should fetch all items across exact page boundaries")
        }
    }

    @Test("Partial last page handled correctly")
    func partialLastPageHandledCorrectly() async throws {
        // 73 playlists = 2 pages (50 + 23)
        let playlists = (0..<73).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            let all = try await client.playlists.allMyPlaylists()

            #expect(all.count == 73, "Should handle partial last page correctly")
            #expect(all.first?.id == "playlist0")
            #expect(all.last?.id == "playlist72")
        }
    }

    // MARK: - Streaming with MaxItems

    @Test("Streaming respects maxItems parameter")
    func streamingRespectsMaxItemsParameter() async throws {
        let playlists = (0..<100).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            var count = 0
            for try await _ in client.playlists.streamMyPlaylists(maxItems: 30) {
                count += 1
            }

            #expect(count == 30, "Should stop at maxItems")
        }
    }

    @Test("Streaming with early break stops correctly")
    func streamingWithEarlyBreakStopsCorrectly() async throws {
        let playlists = (0..<100).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            var collected: [SimplifiedPlaylist] = []
            for try await playlist in client.playlists.streamMyPlaylists() {
                collected.append(playlist)
                if collected.count >= 15 {
                    break
                }
            }

            #expect(collected.count == 15, "Should break correctly at 15 items")
        }
    }

    @Test("Page streaming respects maxPages parameter")
    func pageStreamingRespectsMaxPagesParameter() async throws {
        let playlists = (0..<200).map { index in
            SpotifyTestFixtures.simplifiedPlaylist(
                id: "playlist\(index)",
                name: "Playlist \(index)"
            )
        }
        let configuration = SpotifyMockAPIServer.Configuration(playlists: playlists)
        let server = SpotifyMockAPIServer(configuration: configuration)

        try await server.withRunningServer { info in
            let client = makeUserClient(for: info)

            var pageCount = 0
            for try await _ in client.playlists.streamMyPlaylistPages(maxPages: 3) {
                pageCount += 1
            }

            #expect(pageCount == 3, "Should stop after 3 pages")
        }
    }

    // MARK: - Helpers

    private func makeUserClient(for info: SpotifyMockAPIServer.RunningServer)
        -> SpotifyClient<UserAuthCapability>
    {
        let authenticator = SpotifyClientCredentialsAuthenticator(
            config: .clientCredentials(
                clientID: "pagination-test-client",
                clientSecret: "pagination-test-secret",
                scopes: [.userReadEmail, .playlistReadPrivate],
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

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct CurrentUserPlaylistsStreamTests {

    private func makeClientWithPages(namesPages: [[String]])
        -> UserSpotifyClient
    {
        let pageSize = 2
        let total = namesPages.reduce(0) { $0 + $1.count }

        let responses = namesPages.enumerated().map { index, names in
            let offset = index * pageSize
            let hasNext = index < namesPages.count - 1
            let data = makePlaylistsPageJSON(
                offset: offset,
                limit: pageSize,
                total: total,
                hasNext: hasNext,
                names: names
            )
            return SequencedMockHTTPClient.StubResponse(
                data: data,
                statusCode: 200
            )
        }

        let httpClient = SequencedMockHTTPClient(responses: responses)

        let tokenStore = InMemoryTokenStore(
            tokens: SpotifyTokens(
                accessToken: "ACCESS",
                refreshToken: "REFRESH",
                expiresAt: Date().addingTimeInterval(3600),
                scope: nil,
                tokenType: "Bearer"
            )
        )

        return UserSpotifyClient.authorizationCode(
            clientID: "TEST_CLIENT",
            clientSecret: "TEST_SECRET",
            redirectURI: URL(string: "app://callback")!,
            scopes: [.playlistReadPrivate],
            tokenStore: tokenStore,
            httpClient: httpClient
        )
    }

    @Test
    func streamEmitsAllAcrossPages() async throws {
        let client = makeClientWithPages(namesPages: [
            ["P1", "P2"],
            ["P3", "P4"],
        ])

        var names: [String] = []
        for try await playlist in client.currentUserPlaylistsStream(pageSize: 2)
        {
            names.append(playlist.name)
        }

        #expect(names == ["P1", "P2", "P3", "P4"])
    }

    @Test
    func streamRespectsMaxItems() async throws {
        let client = makeClientWithPages(namesPages: [
            ["P1", "P2"],
            ["P3", "P4"],
        ])

        var names: [String] = []
        for try await playlist in client.currentUserPlaylistsStream(
            pageSize: 2,
            maxItems: 3
        ) {
            names.append(playlist.name)
        }

        #expect(names == ["P1", "P2", "P3"])
    }
}

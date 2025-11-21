import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct ConcurrencyTests {

    @Test
    @MainActor
    func actorIsolation_clientIsSendable() async {
        let (client, _) = makeUserAuthClient()

        // Verify client can be passed across actor boundaries
        let task = Task.detached {
            try? await client.accessToken()
        }

        let token = await task.value
        #expect(token != nil)
    }

    @Test
    @MainActor
    func concurrentTokenAccess_doesNotRace() async throws {
        let (client, _) = makeUserAuthClient()

        // Access token from multiple tasks concurrently
        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    try await client.accessToken()
                }
            }

            var tokens: [String] = []
            for try await token in group {
                tokens.append(token)
            }

            // All tokens should be the same (cached)
            #expect(tokens.count == 20)
            #expect(Set(tokens).count == 1)
        }
    }

    @Test
    @MainActor
    func concurrentServiceCalls_handleCorrectly() async throws {
        let (client, http) = makeUserAuthClient()

        let albumData = try TestDataLoader.load("album_full")
        
        // Only need one response due to request deduplication
        await http.addMockResponse(data: albumData, statusCode: 200)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = try await client.albums.get("test")
                }
            }
            try await group.waitForAll()
        }
        
        let requests = await http.requests
        // With request deduplication, identical concurrent requests share one HTTP call
        #expect(requests.count == 1)
    }

    @Test
    @MainActor
    func streamCancellation_stopsGracefully() async throws {
        let (client, _) = makeUserAuthClient()

        let task = Task {
            var count = 0
            for try await _ in client.streamPages(
                pageSize: 50,
                fetchPage: { limit, offset in
                    try await Task.sleep(for: .milliseconds(100))
                    return Page(
                        href: URL(string: "https://api.spotify.com/v1/test")!,
                        items: ["item"],
                        limit: limit,
                        next: URL(
                            string: "https://api.spotify.com/v1/test?offset=\(offset + limit)")!,
                        offset: offset,
                        previous: nil,
                        total: 10000
                    )
                })
            {
                count += 1
            }
            return count
        }

        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let result = await task.result

        switch result {
        case .success(let count):
            #expect(count < 10)
        case .failure:
            // Cancellation is acceptable
            break
        }
    }

    @Test
    func tokenStore_concurrentAccess() async throws {
        let store = InMemoryTokenStore(tokens: nil)

        // Concurrent save operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let token = SpotifyTokens(
                        accessToken: "TOKEN\(i)",
                        refreshToken: "REFRESH\(i)",
                        expiresAt: Date().addingTimeInterval(3600),
                        scope: nil,
                        tokenType: "Bearer"
                    )
                    try? await store.save(token)
                }
            }
        }

        // Should have one of the tokens saved
        let loaded = try await store.load()
        #expect(loaded != nil)
    }
}

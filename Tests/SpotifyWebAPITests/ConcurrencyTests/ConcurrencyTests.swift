import Foundation
import Testing

@testable import SpotifyWebAPI

private actor OffsetRecorder {
    private var offsets: [Int] = []

    func record(_ offset: Int) {
        offsets.append(offset)
    }

    func snapshot() -> [Int] {
        offsets
    }
}

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
                    return makeStubPage(
                        limit: limit,
                        offset: offset,
                        items: ["item"]
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
    @MainActor
    func streamItems_respectsMaxItemsBudget() async throws {
        let (client, _) = makeUserAuthClient()
        let recorder = OffsetRecorder()

        let stream = client.streamItems(pageSize: 10, maxItems: 15) { limit, offset in
            await recorder.record(offset)
            let values = (0..<limit).map { offset + $0 }
            return makeStubPage(limit: limit, offset: offset, items: values)
        }

        var collected = 0
        for try await _ in stream {
            collected += 1
        }

        #expect(collected == 15)
        let offsets = await recorder.snapshot()
        #expect(offsets == [0, 10])
    }

    @Test
    @MainActor
    func serviceStreamCancellation_preventsAdditionalRequests() async throws {
        let (client, http) = makeUserAuthClient()
        let firstPage = try makePaginatedResponse(
            fixture: "top_tracks.json",
            of: Track.self,
            offset: 0,
            limit: 20,
            total: 100,
            hasNext: true
        )
        let secondPage = try makePaginatedResponse(
            fixture: "top_tracks.json",
            of: Track.self,
            offset: 20,
            limit: 20,
            total: 100,
            hasNext: true
        )

        await http.addMockResponse(data: firstPage, statusCode: 200, delay: .seconds(2))
        await http.addMockResponse(data: secondPage, statusCode: 200)

        let task = Task { () -> Int in
            var count = 0
            let stream = await client.users.streamTopTrackPages(pageSize: 20)
            for try await page in stream {
                count += page.items.count
            }
            return count
        }

        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let result = await task.result
        switch result {
        case .success(let count):
            #expect(count == 0, "Stream should not emit items after cancellation")
        case .failure(let error):
            #expect(error is CancellationError)
        }

        let requests = await http.requests
        #expect(requests.count == 1)
    }

    @Test
    @MainActor
    func collectAllPagesCancellationStopsRequests() async {
        let (client, _) = makeUserAuthClient()

        let task = Task<[String], Error> {
            try await client.collectAllPages(pageSize: 50, maxItems: nil) { limit, offset in
                try await Task.sleep(for: .milliseconds(100))
                return makeStubPage(
                    limit: limit,
                    offset: offset,
                    items: (0..<limit).map { "item-\(offset + $0)" }
                )
            }
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        let result = await task.result
        switch result {
        case .success:
            Issue.record("Expected collectAllPages to be cancelled")
        case .failure(let error):
            if !(error is CancellationError) {
                Issue.record("Expected cancellation, got \(error)")
            }
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

    @Test
    func tokenStore_concurrentFailureInjection() async {
        let store = InMemoryTokenStore(tokens: nil)
        await store.configureFailures([.saveFailed])

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for i in 0..<5 {
                    group.addTask {
                        let token = SpotifyTokens(
                            accessToken: "FAIL\(i)",
                            refreshToken: "REFRESH\(i)",
                            expiresAt: Date().addingTimeInterval(3600),
                            scope: nil,
                            tokenType: "Bearer"
                        )
                        try await store.save(token)
                    }
                }

                try await group.waitForAll()
            }
            Issue.record("Expected save failures to be thrown")
        } catch let error as InMemoryTokenStore.Failure {
            #expect(error == .saveFailed)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

}

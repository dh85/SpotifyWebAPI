import Foundation
import Testing

@testable import SpotifyKit

@Suite("Offline Mode Tests")
@MainActor
struct OfflineModeTests {

    // MARK: - Offline Flag Tests

    @Test("Client starts in online mode by default")
    func startsOnline() async {
        let (client, _) = makeUserAuthClient()
        let isOffline = await client.isOffline()
        #expect(!isOffline)
    }

    @Test("setOffline enables offline mode")
    func enableOffline() async {
        let (client, _) = makeUserAuthClient()

        await client.setOffline(true)
        let isOffline = await client.isOffline()
        #expect(isOffline)
    }

    @Test("setOffline can toggle offline mode")
    func toggleOffline() async {
        let (client, _) = makeUserAuthClient()

        // Enable offline
        await client.setOffline(true)
        var isOffline = await client.isOffline()
        #expect(isOffline)

        // Disable offline
        await client.setOffline(false)
        isOffline = await client.isOffline()
        #expect(!isOffline)

        // Enable again
        await client.setOffline(true)
        isOffline = await client.isOffline()
        #expect(isOffline)
    }

    // MARK: - Request Blocking Tests

    @Test("Requests fail when offline mode is enabled")
    func requestsFailWhenOffline() async {
        let (client, http) = makeUserAuthClient()

        // Set up a mock response (won't be used)
        await http.addMockResponse(
            data: "{\"id\": \"album123\"}".data(using: .utf8)!,
            statusCode: 200
        )

        // Enable offline mode
        await client.setOffline(true)

        // Attempt to make a request
        do {
            _ = try await client.albums.get("album123")
            Issue.record("Expected offline error but request succeeded")
        } catch let error as SpotifyClientError {
            #expect(error == .offline)
        } catch {
            Issue.record("Expected SpotifyClientError.offline but got \(error)")
        }

        // Verify no network request was made
        let requests = await http.requests
        #expect(requests.isEmpty)
    }

    @Test("Requests succeed when offline mode is disabled")
    func requestsSucceedWhenOnline() async throws {
        let (client, http) = makeUserAuthClient()

        let albumJSON = """
            {
                "id": "album123",
                "name": "Test Album",
                "album_type": "album",
                "artists": [],
                "images": [],
                "release_date": "2023-01-01",
                "total_tracks": 10,
                "type": "album",
                "uri": "spotify:album:album123"
            }
            """

        await http.addMockResponse(data: albumJSON.data(using: .utf8)!, statusCode: 200)

        // Ensure offline mode is disabled
        await client.setOffline(false)

        // Request should succeed
        let album = try await client.albums.get("album123")
        #expect(album.id == "album123")

        // Verify network request was made
        let requests = await http.requests
        #expect(requests.count == 1)
    }

    @Test("Multiple request types all blocked when offline")
    func multipleRequestTypesBlocked() async {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(data: Data(), statusCode: 200)

        await client.setOffline(true)

        // Test GET request
        do {
            _ = try await client.albums.get("album123")
            Issue.record("GET request should have failed")
        } catch SpotifyClientError.offline {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Test POST request (save albums)
        do {
            try await client.albums.save(["album1", "album2"])
            Issue.record("POST request should have failed")
        } catch SpotifyClientError.offline {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // Test DELETE request (remove albums)
        do {
            try await client.albums.remove(["album1"])
            Issue.record("DELETE request should have failed")
        } catch SpotifyClientError.offline {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        // No requests should have been made
        let requests = await http.requests
        #expect(requests.isEmpty)
    }

    // MARK: - Re-enable After Offline Tests

    @Test("Requests work after re-enabling from offline mode")
    func requestsWorkAfterReEnable() async throws {
        let (client, http) = makeUserAuthClient()

        let albumJSON = """
            {
                "id": "album456",
                "name": "Another Album",
                "album_type": "album",
                "artists": [],
                "images": [],
                "release_date": "2023-06-15",
                "total_tracks": 8,
                "type": "album",
                "uri": "spotify:album:album456"
            }
            """

        await http.addMockResponse(data: albumJSON.data(using: .utf8)!, statusCode: 200)

        // Enable offline mode
        await client.setOffline(true)

        // Request should fail
        do {
            _ = try await client.albums.get("album456")
            Issue.record("Should have failed in offline mode")
        } catch SpotifyClientError.offline {
            // Expected
        }

        // Disable offline mode
        await client.setOffline(false)

        // Add mock response for retry
        await http.addMockResponse(data: albumJSON.data(using: .utf8)!, statusCode: 200)

        // Request should now succeed
        let album = try await client.albums.get("album456")
        #expect(album.id == "album456")

        // Verify request was made
        let requests = await http.requests
        #expect(requests.count == 1)
    }

    // MARK: - Batch Operation Tests

    @Test("Batch operations blocked when offline")
    func batchOperationsBlocked() async {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(data: Data(), statusCode: 200)

        await client.setOffline(true)

        let albumIDs = (1...50).map { "album\($0)" }

        do {
            try await client.albums.saveAll(albumIDs)
            Issue.record("Batch operation should have failed")
        } catch SpotifyClientError.offline {
            // Expected - should fail on first batch attempt
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let requests = await http.requests
        #expect(requests.isEmpty)
    }

    // MARK: - Concurrent Request Tests

    @Test("Offline mode blocks concurrent requests")
    func offlineBlocksConcurrentRequests() async {
        let (client, http) = makeUserAuthClient()

        // Add mock responses
        for _ in 0..<5 {
            await http.addMockResponse(data: Data(), statusCode: 200)
        }

        await client.setOffline(true)

        // Launch multiple concurrent requests
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        _ = try await client.albums.get("album\(i)")
                        return false  // Should not succeed
                    } catch SpotifyClientError.offline {
                        return true  // Expected
                    } catch {
                        return false  // Wrong error
                    }
                }
            }

            var allOfflineErrors = true
            for await result in group {
                if !result {
                    allOfflineErrors = false
                }
            }

            #expect(allOfflineErrors)
        }

        let requests = await http.requests
        #expect(requests.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("isOffline can be checked multiple times without side effects")
    func isOfflineMultipleCalls() async {
        let (client, _) = makeUserAuthClient()

        await client.setOffline(true)

        // Check multiple times
        var isOffline = await client.isOffline()
        #expect(isOffline)
        isOffline = await client.isOffline()
        #expect(isOffline)
        isOffline = await client.isOffline()
        #expect(isOffline)

        await client.setOffline(false)

        isOffline = await client.isOffline()
        #expect(!isOffline)
        isOffline = await client.isOffline()
        #expect(!isOffline)
    }

    @Test("Offline mode persists across multiple operations")
    func offlineModePersists() async {
        let (client, _) = makeUserAuthClient()

        await client.setOffline(true)

        // Attempt multiple different operations
        for _ in 0..<3 {
            do {
                _ = try await client.albums.get("test")
            } catch SpotifyClientError.offline {
                // Expected
            } catch {
                Issue.record("Wrong error: \(error)")
            }

            // Check it's still offline
            let stillOffline = await client.isOffline()
            #expect(stillOffline)
        }
    }
}

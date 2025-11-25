import Foundation
import Testing
@testable import SpotifyWebAPI

// MARK: - Tests

@Suite("Batch Progress Tests")
@MainActor
struct BatchProgressTests {
    
    // MARK: - BatchProgress Model Tests
    
    @Test("BatchProgress equality works correctly")
    func batchProgressEquality() {
        let progress1 = BatchProgress(completed: 2, total: 5, currentBatchSize: 20)
        let progress2 = BatchProgress(completed: 2, total: 5, currentBatchSize: 20)
        let progress3 = BatchProgress(completed: 3, total: 5, currentBatchSize: 20)
        
        #expect(progress1 == progress2)
        #expect(progress1 != progress3)
    }
    
    // MARK: - Albums Batch Progress Tests
    
    @Test("Albums saveAll reports progress correctly")
    func albumsSaveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        // 55 albums will create 3 batches (20, 20, 15)
        let albumIDs = (1...55).map { "album\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.albums.saveAll(albumIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 3)
        
        // Check first batch
        #expect(recorded[0].completed == 0)
        #expect(recorded[0].total == 3)
        #expect(recorded[0].currentBatchSize == 20)
        
        // Check second batch
        #expect(recorded[1].completed == 1)
        #expect(recorded[1].total == 3)
        #expect(recorded[1].currentBatchSize == 20)
        
        // Check third batch
        #expect(recorded[2].completed == 2)
        #expect(recorded[2].total == 3)
        #expect(recorded[2].currentBatchSize == 15)
    }
    
    @Test("Albums removeAll reports progress correctly")
    func albumsRemoveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        // 25 albums will create 2 batches (20, 5)
        let albumIDs = (1...25).map { "album\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.albums.removeAll(albumIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2)
        #expect(recorded[0].completed == 0)
        #expect(recorded[0].currentBatchSize == 20)
        #expect(recorded[1].completed == 1)
        #expect(recorded[1].currentBatchSize == 5)
    }
    
    // MARK: - Tracks Batch Progress Tests
    
    @Test("Tracks saveAll reports progress correctly")
    func tracksSaveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        // 120 tracks will create 3 batches (50, 50, 20)
        let trackIDs = (1...120).map { "track\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.tracks.saveAll(trackIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 3)
        #expect(recorded[0].currentBatchSize == 50)
        #expect(recorded[1].currentBatchSize == 50)
        #expect(recorded[2].currentBatchSize == 20)
    }
    
    @Test("Tracks removeAll reports progress correctly")
    func tracksRemoveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let trackIDs = (1...75).map { "track\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.tracks.removeAll(trackIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2)
        #expect(recorded[0].total == 2)
        #expect(recorded[1].total == 2)
    }
    
    // MARK: - Shows Batch Progress Tests
    
    @Test("Shows saveAll reports progress correctly")
    func showsSaveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let showIDs = (1...100).map { "show\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.shows.saveAll(showIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2)
        #expect(recorded[0].currentBatchSize == 50)
        #expect(recorded[1].currentBatchSize == 50)
    }
    
    @Test("Shows removeAll reports progress correctly")
    func showsRemoveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let showIDs = (1...60).map { "show\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.shows.removeAll(showIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2)
        #expect(recorded[0].completed == 0)
        #expect(recorded[1].completed == 1)
    }
    
    // MARK: - Episodes Batch Progress Tests
    
    @Test("Episodes saveAll reports progress correctly")
    func episodesSaveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let episodeIDs = (1...130).map { "episode\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.episodes.saveAll(episodeIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 3)
        #expect(recorded[2].currentBatchSize == 30)
    }
    
    @Test("Episodes removeAll reports progress correctly")
    func episodesRemoveAllProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let episodeIDs = (1...50).map { "episode\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.episodes.removeAll(episodeIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 1)
        #expect(recorded[0].currentBatchSize == 50)
    }
    
    // MARK: - Playlists Batch Progress Tests
    
    @Test("Playlists addTracks reports progress correctly")
    func playlistsAddTracksProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        // 250 tracks will create 3 batches (100, 100, 50)
        let trackURIs = (1...250).map { "spotify:track:track\($0)" }
        let playlistID = "playlist123"
        
        let snapshotJSON = "{\"snapshot_id\": \"abc123\"}"
        await http.addMockResponse(data: snapshotJSON.data(using: .utf8)!, statusCode: 200)
        await http.addMockResponse(data: snapshotJSON.data(using: .utf8)!, statusCode: 200)
        await http.addMockResponse(data: snapshotJSON.data(using: .utf8)!, statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.playlists.addTracks(trackURIs, to: playlistID) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 3)
        #expect(recorded[0].completed == 0)
        #expect(recorded[0].total == 3)
        #expect(recorded[0].currentBatchSize == 100)
        #expect(recorded[2].currentBatchSize == 50)
    }
    
    @Test("Playlists removeTracks reports progress correctly")
    func playlistsRemoveTracksProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let trackURIs = (1...150).map { "spotify:track:track\($0)" }
        let playlistID = "playlist456"
        
        let snapshotJSON = "{\"snapshot_id\": \"def456\"}"
        await http.addMockResponse(data: snapshotJSON.data(using: .utf8)!, statusCode: 200)
        await http.addMockResponse(data: snapshotJSON.data(using: .utf8)!, statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.playlists.removeTracks(trackURIs, from: playlistID) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2)
        #expect(recorded[0].total == 2)
        #expect(recorded[1].total == 2)
    }
    
    // MARK: - Edge Cases
    
    @Test("Progress callback not invoked when empty array provided")
    func emptyArrayNoProgress() async throws {
        let (client, _) = makeUserAuthClient()
        
        let holder = ProgressHolder()
        
        try await client.albums.saveAll([]) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.isEmpty)
    }
    
    @Test("Progress callback works with single batch")
    func singleBatchProgress() async throws {
        let (client, http) = makeUserAuthClient()
        
        let albumIDs = (1...10).map { "album\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.albums.saveAll(albumIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 1)
        #expect(recorded[0].completed == 0)
        #expect(recorded[0].total == 1)
        #expect(recorded[0].currentBatchSize == 10)
    }
    
    @Test("Batch operations work without progress callback")
    func noCallbackStillWorks() async throws {
        let (client, http) = makeUserAuthClient()
        
        let albumIDs = (1...25).map { "album\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        // Should not throw when callback is nil
        try await client.albums.saveAll(albumIDs)
        
        // Verify the mock was called (2 batches expected)
        let requests = await http.requests
        #expect(requests.count == 2)
    }
    
    @Test("Progress deduplicates IDs correctly")
    func progressWithDuplicateIDs() async throws {
        let (client, http) = makeUserAuthClient()
        
        // 30 IDs with duplicates - should dedupe to 25 unique, creating 2 batches
        let albumIDs = (1...25).map { "album\($0)" } + (1...5).map { "album\($0)" }
        
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        
        let holder = ProgressHolder()
        
        try await client.albums.saveAll(albumIDs) { progress in
            Task {
                await holder.add(progress)
            }
        }
        
        let recorded = await holder.progressReports
        #expect(recorded.count == 2) // 25 unique items = 2 batches of 20 and 5
        #expect(recorded[1].currentBatchSize == 5)
    }
}

// MARK: - Test Helpers

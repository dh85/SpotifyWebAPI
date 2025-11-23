import Testing

@testable import SpotifyWebAPI

@Suite("PlaylistsService Extensions Tests")
@MainActor
struct PlaylistsServiceExtensionsTests {

    @Test("addTracks chunks into batches of 100")
    func addTracksChunking() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 201)
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 201)
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap3"}"#.data(using: .utf8)!, statusCode: 201)

        let uris = (1...250).map { "spotify:track:\($0)" }
        try await client.playlists.addTracks(uris, to: "playlist123")

        let requests = await http.requests
        #expect(requests.count == 3)
        #expect(requests.allSatisfy { $0.url?.path == "/v1/playlists/playlist123/tracks" })
    }

    @Test("addTracks handles single batch")
    func addTracksSingleBatch() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 201)

        let uris = (1...50).map { "spotify:track:\($0)" }
        try await client.playlists.addTracks(uris, to: "playlist123")

        let requests = await http.requests
        #expect(requests.count == 1)
    }

    @Test("removeTracks chunks into batches of 100")
    func removeTracksChunking() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap1"}"#.data(using: .utf8)!, statusCode: 200)
        await http.addMockResponse(
            data: #"{"snapshot_id":"snap2"}"#.data(using: .utf8)!, statusCode: 200)

        let uris = (1...150).map { "spotify:track:\($0)" }
        try await client.playlists.removeTracks(uris, from: "playlist123")

        let requests = await http.requests
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.url?.path == "/v1/playlists/playlist123/tracks" })
    }

    @Test("Array chunked helper")
    func arrayChunking() {
        let array = Array(1...10)
        let chunks = array.chunked(into: 3)

        #expect(chunks.count == 4)
        #expect(chunks[0] == [1, 2, 3])
        #expect(chunks[1] == [4, 5, 6])
        #expect(chunks[2] == [7, 8, 9])
        #expect(chunks[3] == [10])
    }
}

// MARK: - Test Helpers

extension Array {
    fileprivate func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

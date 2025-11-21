import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Library Service Extensions Tests")
@MainActor
struct LibraryServiceExtensionsTests {

    @Test("Albums saveAll chunks into batches of 20")
    func albumsSaveAllChunking() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)

        let ids = (1...45).map { "album\($0)" }
        try await client.albums.saveAll(ids)

        let requests = await http.requests
        #expect(requests.count == 3)
        #expect(requests.allSatisfy { $0.url?.path == "/v1/me/albums" })
    }

    @Test("Tracks saveAll chunks into batches of 50")
    func tracksSaveAllChunking() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)

        let ids = (1...120).map { "track\($0)" }
        try await client.tracks.saveAll(ids)

        let requests = await http.requests
        #expect(requests.count == 3)
        #expect(requests.allSatisfy { $0.url?.path == "/v1/me/tracks" })
    }

    @Test("Shows removeAll chunks into batches of 50")
    func showsRemoveAllChunking() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(data: Data(), statusCode: 200)
        await http.addMockResponse(data: Data(), statusCode: 200)

        let ids = (1...75).map { "show\($0)" }
        try await client.shows.removeAll(ids)

        let requests = await http.requests
        #expect(requests.count == 2)
        #expect(requests.allSatisfy { $0.url?.path == "/v1/me/shows" })
    }

    @Test("Episodes saveAll handles single batch")
    func episodesSaveAllSingleBatch() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(data: Data(), statusCode: 200)

        let ids = (1...30).map { "episode\($0)" }
        try await client.episodes.saveAll(ids)

        let requests = await http.requests
        #expect(requests.count == 1)
    }

    @Test("Set chunked helper")
    func setChunking() {
        let set = Set(1...10)
        let chunks = set.chunked(into: 3)

        #expect(chunks.count == 4)
        #expect(chunks.reduce(0) { $0 + $1.count } == 10)
        #expect(chunks.allSatisfy { $0.count <= 3 })
    }
}

// MARK: - Test Helpers

extension Set {
    fileprivate func chunked(into size: Int) -> [Set<Element>] {
        let array = Array(self)
        return stride(from: 0, to: array.count, by: size).map {
            Set(array[$0..<Swift.min($0 + size, array.count)])
        }
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct PerformanceTests {

    @Test(.timeLimit(.minutes(1)))
    func decodingLargePagePerformance() async throws {
        let data = try TestDataLoader.load("album_full")

        let iterations = 100
        let start = Date()

        for _ in 0..<iterations {
            let _: Album = try decodeModel(from: data)
        }

        let duration = Date().timeIntervalSince(start)
        let avgTime = duration / Double(iterations)

        #expect(avgTime < 0.01, "Average decode time: \(avgTime)s")
    }

    @Test(.timeLimit(.minutes(1)))
    @MainActor
    func concurrentRequestsPerformance() async throws {
        let (client, http) = makeUserAuthClient()

        for _ in 0..<10 {
            let data = try TestDataLoader.load("current_user_profile")
            await http.addMockResponse(
                data: data,
                statusCode: 200,
                url: URL(string: "https://api.spotify.com/v1/me")!
            )
        }

        let start = Date()

        try await withThrowingTaskGroup(of: CurrentUserProfile.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try await client.users.me()
                }
            }

            var count = 0
            for try await _ in group {
                count += 1
            }

            #expect(count == 10)
        }

        let duration = Date().timeIntervalSince(start)
        #expect(duration < 0.5, "Duration: \(duration)s")
    }
}

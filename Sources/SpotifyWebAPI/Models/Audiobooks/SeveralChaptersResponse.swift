import Foundation

/// Wrapper for the `GET /v1/chapters` endpoint response.
struct SeveralChaptersResponse: Codable, Sendable, Equatable {
    let chapters: [Chapter]
}

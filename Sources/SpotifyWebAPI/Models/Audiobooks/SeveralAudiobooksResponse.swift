import Foundation

/// Wrapper for the `GET /v1/audiobooks` endpoint response.
struct SeveralAudiobooksResponse: Codable, Sendable, Equatable {
    let audiobooks: [Audiobook]
}

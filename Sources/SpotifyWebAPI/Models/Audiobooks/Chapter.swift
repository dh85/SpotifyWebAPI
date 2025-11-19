import Foundation

/// A Full Chapter Object.
/// Source: GET /v1/chapters/{id}
public struct Chapter: Codable, Sendable, Equatable {
    public let availableMarkets: [String]?
    public let chapterNumber: Int
    public let description: String
    public let htmlDescription: String
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls
    public let href: URL
    public let id: String
    public let images: [SpotifyImage]
    public let isPlayable: Bool?
    public let languages: [String]
    public let name: String
    public let releaseDate: String
    public let releaseDatePrecision: String
    public let resumePoint: ResumePoint?
    public let type: MediaType
    public let uri: String
    public let restrictions: Restriction?
    public let audiobook: Audiobook

    @available(
        *,
        deprecated,
        message:
            "Deprecated by Spotify. Spotify Audio preview clips can not be a standalone service."
    )
    public let audioPreviewUrl: URL?
}

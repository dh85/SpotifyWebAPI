import Foundation

/// A Full Chapter Object.
/// Source: GET /v1/chapters/{id}
public struct Chapter: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let htmlDescription: String
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL
    public let uri: String
    public let images: [SpotifyImage]
    public let previewUrl: URL?

    /// The audiobook for this chapter.
    public let audiobook: SimplifiedAudiobook

    /// The date the chapter was first released.
    public let releaseDate: String

    /// The precision of the release date (e.g., "day").
    public let releaseDatePrecision: String

    /// A list of the languages used in the chapter.
    public let languages: [String]
}

import Foundation

/// A Full Episode Object.
/// Source: GET /v1/episodes/{id}
public struct Episode: Codable, Sendable, Equatable {
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

    /// The show for this episode.
    public let show: SimplifiedShow

    /// The date the episode was first released.
    public let releaseDate: String

    /// The precision of the release date (e.g., "day").
    public let releaseDatePrecision: String

    /// A list of the languages used in the episode.
    public let languages: [String]

    /// The user's resume point for this episode.
    /// Requires the `user-read-playback-position` scope.
    public let resumePoint: ResumePoint?
}

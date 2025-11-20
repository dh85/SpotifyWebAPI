import Foundation

/// A full episode object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-episode)
public struct Episode: Codable, Sendable, Equatable {
    /// Episode description with HTML tags stripped.
    public let description: String
    /// Episode description with HTML tags.
    public let htmlDescription: String
    /// Episode length in milliseconds.
    public let durationMs: Int
    /// Whether the episode has explicit content.
    public let explicit: Bool
    /// External URLs for this episode.
    public let externalUrls: SpotifyExternalUrls
    /// API endpoint URL for full episode details.
    public let href: URL
    /// The Spotify ID.
    public let id: String
    /// Cover art images in various sizes.
    public let images: [SpotifyImage]
    /// Whether the episode is hosted outside Spotify's CDN.
    public let isExternallyHosted: Bool
    /// Whether the episode is playable in the given market.
    public let isPlayable: Bool?
    /// Languages used in the episode (ISO 639-1 codes).
    public let languages: [String]
    /// Episode name.
    public let name: String
    /// Release date (e.g., "1981-12-15").
    public let releaseDate: String
    /// Precision of the release date.
    public let releaseDatePrecision: ReleaseDatePrecision
    /// User's most recent playback position. Requires `user-read-playback-position` scope.
    public let resumePoint: ResumePoint?
    /// Object type (always "episode").
    public let type: MediaType
    /// The Spotify URI.
    public let uri: String
    /// Content restriction information.
    public let restrictions: Restriction?
    /// The show this episode belongs to.
    public let show: SimplifiedShow

    @available(
        *,
        deprecated,
        message:
            "Deprecated by Spotify. Spotify Audio preview clips can not be a standalone service."
    )
    public let audioPreviewUrl: URL?

    @available(
        *,
        deprecated,
        message: "Deprecated by Spotify."
    )
    public let language: String?
}

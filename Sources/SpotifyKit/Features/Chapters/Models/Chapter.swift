import Foundation

/// A full chapter object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-chapter)
public struct Chapter: Codable, Sendable, Equatable {
    /// Markets where the chapter is available (ISO 3166-1 alpha-2 codes).
    public let availableMarkets: [String]?
    /// Chapter number.
    public let chapterNumber: Int
    /// Chapter description with HTML tags stripped.
    public let description: String
    /// Chapter description with HTML tags.
    public let htmlDescription: String
    /// Chapter length in milliseconds.
    public let durationMs: Int
    /// Whether the chapter has explicit content.
    public let explicit: Bool
    /// External URLs for this chapter.
    public let externalUrls: SpotifyExternalUrls
    /// API endpoint URL for full chapter details.
    public let href: URL
    /// The Spotify ID.
    public let id: String
    /// Cover art images in various sizes.
    public let images: [SpotifyImage]
    /// Whether the chapter is playable in the given market.
    public let isPlayable: Bool?
    /// Languages used in the chapter (ISO 639-1 codes).
    public let languages: [String]
    /// Chapter name.
    public let name: String
    /// Release date (e.g., "1981-12-15").
    public let releaseDate: String
    /// Precision of the release date.
    public let releaseDatePrecision: String
    /// User's most recent playback position. Requires `user-read-playback-position` scope.
    public let resumePoint: ResumePoint?
    /// Object type (always "chapter").
    public let type: SpotifyObjectType
    /// The Spotify URI.
    public let uri: String
    /// Content restriction information.
    public let restrictions: Restriction?
    /// The audiobook this chapter belongs to.
    public let audiobook: Audiobook
}

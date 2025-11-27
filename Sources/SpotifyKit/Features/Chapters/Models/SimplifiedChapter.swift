import Foundation

/// Simplified chapter object containing core chapter information.
///
/// This is a lighter version of the full Chapter object, typically returned in contexts
/// where complete chapter details are not needed (e.g., within audiobooks).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-chapter)
public struct SimplifiedChapter: Codable, Sendable, Equatable {
    /// A list of the countries in which the chapter can be played (ISO 3166-1 alpha-2 country codes).
    public let availableMarkets: [String]?
    /// The number of the chapter.
    public let chapterNumber: Int
    /// A description of the chapter.
    public let description: String
    /// A description of the chapter in HTML format.
    public let htmlDescription: String
    /// The chapter length in milliseconds.
    public let durationMs: Int
    /// Whether or not the chapter has explicit content.
    public let explicit: Bool
    /// Known external URLs for this chapter.
    public let externalUrls: SpotifyExternalUrls
    /// A link to the Web API endpoint providing full details of the chapter.
    public let href: URL
    /// The Spotify ID for the chapter.
    public let id: String
    /// The cover art for the chapter in various sizes.
    public let images: [SpotifyImage]
    /// True if the chapter is playable in the given market. Otherwise false.
    public let isPlayable: Bool?
    /// A list of the languages used in the chapter (ISO 639 codes).
    public let languages: [String]
    /// The name of the chapter.
    public let name: String
    /// The date the chapter was first released.
    public let releaseDate: String
    /// The precision with which release_date value is known (year, month, or day).
    public let releaseDatePrecision: ReleaseDatePrecision
    /// The user's most recent position in the chapter.
    public let resumePoint: ResumePoint?
    /// The object type (always "episode").
    public let type: SpotifyObjectType
    /// The Spotify URI for the chapter.
    public let uri: String
    /// Included when a content restriction is applied.
    public let restrictions: Restriction?
}

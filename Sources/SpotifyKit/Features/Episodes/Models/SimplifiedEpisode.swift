import Foundation

/// Simplified episode object containing core episode information.
///
/// This is a lighter version of the full Episode object, typically returned in contexts
/// where complete episode details are not needed (e.g., within shows, search results).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-episode)
public struct SimplifiedEpisode: Codable, Sendable, Equatable {
    /// A description of the episode.
    public let description: String?
    /// A description of the episode in HTML format.
    public let htmlDescription: String?
    /// The episode length in milliseconds.
    public let durationMs: Int?
    /// Whether or not the episode has explicit content.
    public let explicit: Bool
    /// Known external URLs for this episode.
    public let externalUrls: SpotifyExternalUrls?
    /// A link to the Web API endpoint providing full details of the episode.
    public let href: URL?
    /// The Spotify ID for the episode.
    public let id: String?
    /// The cover art for the episode in various sizes.
    public let images: [SpotifyImage]?
    /// True if the episode is hosted outside of Spotify's CDN.
    public let isExternallyHosted: Bool?
    /// True if the episode is playable in the given market. Otherwise false.
    public let isPlayable: Bool?
    /// A list of the languages used in the episode (ISO 639 codes).
    public let languages: [String]?
    /// The name of the episode.
    public let name: String?
    /// The date the episode was first released.
    public let releaseDate: String?
    /// The precision with which release_date value is known (year, month, or day).
    public let releaseDatePrecision: ReleaseDatePrecision?
    /// The user's most recent position in the episode.
    public let resumePoint: ResumePoint?
    /// The object type (always "episode").
    public let type: SpotifyObjectType
    /// The Spotify URI for the episode.
    public let uri: String?
    /// Included when a content restriction is applied.
    public let restrictions: Restriction?
}

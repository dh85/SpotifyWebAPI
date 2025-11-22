import Foundation

/// A full show (podcast) object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-show)
public struct Show: Codable, Sendable, Equatable {
    /// Markets where the show is available (ISO 3166-1 alpha-2 codes).
    public let availableMarkets: [String]?
    /// Copyright statements.
    public let copyrights: [SpotifyCopyright]?
    /// Show description with HTML tags stripped.
    public let description: String?
    /// Show description with HTML tags.
    public let htmlDescription: String?
    /// Whether the show has explicit content.
    public let explicit: Bool
    /// External URLs for the show.
    public let externalUrls: SpotifyExternalUrls?
    /// API endpoint URL for full show details.
    public let href: URL?
    /// The Spotify ID.
    public let id: String?
    /// Cover art images in various sizes.
    public let images: [SpotifyImage]?
    /// True if the show is hosted outside of Spotify's CDN.
    public let isExternallyHosted: Bool?
    /// A list of the languages used in the show, identified by their ISO 639-1 code.
    public let languages: [String]?
    /// Media type.
    public let mediaType: String?
    /// Show name.
    public let name: String?
    /// Publisher name.
    public let publisher: String?
    /// The object type.
    public let type: SpotifyObjectType
    /// The Spotify URI.
    public let uri: String?
    /// Total number of episodes.
    public let totalEpisodes: Int?
    /// Episodes in the show.
    public let episodes: Page<SimplifiedEpisode>?
}

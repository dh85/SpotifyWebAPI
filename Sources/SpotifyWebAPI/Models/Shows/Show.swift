import Foundation

/// A Full Show Object.
/// Source: GET /v1/shows/{id}
public struct Show: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let htmlDescription: String
    public let publisher: String
    public let mediaType: String
    public let explicit: Bool
    public let totalEpisodes: Int
    public let href: URL
    public let uri: String
    public let images: [SpotifyImage]
    public let copyrights: [SpotifyCopyright]

    /// A list of ISO 3166-1 alpha-2 country codes.
    public let availableMarkets: [String]?

    /// The episodes of the show.
    public let episodes: Page<SimplifiedEpisode>
}

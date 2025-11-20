import Foundation

/// A Simplified Show Object.
/// (Used inside the 'Episode' model)
public struct SimplifiedShow: Codable, Sendable, Equatable {
    public let availableMarkets: [String]?
    public let copyrights: [SpotifyCopyright]
    public let description: String
    public let htmlDescription: String
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls
    public let href: URL
    public let id: String
    public let images: [SpotifyImage]
    public let isExternallyHosted: Bool
    public let languages: [String]
    public let mediaType: String
    public let name: String
    public let publisher: String
    public let type: MediaType
    public let uri: String
    public let totalEpisodes: Int

}

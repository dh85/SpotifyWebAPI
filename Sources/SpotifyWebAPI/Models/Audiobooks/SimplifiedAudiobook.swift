import Foundation

/// A Simplified Audiobook Object.
/// (Used inside the 'Chapter' model)
public struct SimplifiedAudiobook: Codable, Sendable, Equatable {
    public let authors: [Author]
    public let availableMarkets: [String]
    public let copyrights: [SpotifyCopyright]
    public let description: String
    public let htmlDescription: String
    public let edition: String?
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls
    public let href: URL
    public let id: String
    public let images: [SpotifyImage]
    public let languages: [String]
    public let mediaType: String
    public let name: String
    public let narrators: [Narrator]
    public let publisher: String
    public let type: MediaType
    public let uri: String
    public let totalChapters: Int
}

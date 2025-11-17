import Foundation

/// A Simplified Audiobook Object.
/// (Used inside the 'Chapter' model)
public struct SimplifiedAudiobook: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let htmlDescription: String
    public let publisher: String
    public let mediaType: String
    public let explicit: Bool
    public let totalChapters: Int
    public let href: URL
    public let uri: String
    public let images: [SpotifyImage]

    /// The authors of the audiobook.
    public let authors: [SimplifiedArtist]

    /// The narrators of the audiobook.
    public let narrators: [SimplifiedArtist]

    /// Copyrights for the audiobook.
    public let copyrights: [SpotifyCopyright]

    /// A list of ISO 3166-1 alpha-2 country codes.
    public let availableMarkets: [String]?
}

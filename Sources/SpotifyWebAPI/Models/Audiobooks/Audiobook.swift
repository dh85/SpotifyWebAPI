import Foundation

/// A Full Audiobook Object.
/// Source: GET /v1/audiobooks/{id}
public struct Audiobook: Codable, Sendable, Equatable {
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

    /// The authors of the audiobook. Reuses the SimplifiedArtist model.
    public let authors: [SimplifiedArtist]

    /// The narrators of the audiobook. Reuses the SimplifiedArtist model.
    public let narrators: [SimplifiedArtist]

    /// Copyrights for the audiobook.
    public let copyrights: [SpotifyCopyright]

    /// The chapters of the audiobook, returned in a paged object.
    public let chapters: Page<SimplifiedChapter>
}

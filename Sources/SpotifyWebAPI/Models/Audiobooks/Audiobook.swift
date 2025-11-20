import Foundation

/// A full audiobook object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
public struct Audiobook: Codable, Sendable, Equatable {
    /// Authors of the audiobook.
    public let authors: [Author]
    /// Markets where the audiobook is available (ISO 3166-1 alpha-2 codes).
    public let availableMarkets: [String]
    /// Copyright statements.
    public let copyrights: [SpotifyCopyright]
    /// Audiobook description with HTML tags stripped.
    public let description: String
    /// Audiobook description with HTML tags.
    public let htmlDescription: String
    /// Edition of the audiobook.
    public let edition: String?
    /// Whether the audiobook has explicit content.
    public let explicit: Bool
    /// External URLs for this audiobook.
    public let externalUrls: SpotifyExternalUrls
    /// API endpoint URL for full audiobook details.
    public let href: URL
    /// The Spotify ID.
    public let id: String
    /// Cover art images in various sizes.
    public let images: [SpotifyImage]
    /// Languages used in the audiobook (ISO 639-1 codes).
    public let languages: [String]
    /// Media type (always "audio").
    public let mediaType: String
    /// Audiobook name.
    public let name: String
    /// Narrators of the audiobook.
    public let narrators: [Narrator]
    /// Publisher name.
    public let publisher: String
    /// Object type (always "audiobook").
    public let type: MediaType
    /// The Spotify URI.
    public let uri: String
    /// Total number of chapters.
    public let totalChapters: Int
    /// Chapters in the audiobook.
    public let chapters: Page<SimplifiedChapter>?
}

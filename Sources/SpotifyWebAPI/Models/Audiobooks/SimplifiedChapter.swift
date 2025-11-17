import Foundation

/// A Simplified Chapter Object.
public struct SimplifiedChapter: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL
    public let uri: String
    public let images: [SpotifyImage]
    public let previewUrl: URL?

    // Note: The full 'Chapter' object has more fields
    // This is the 'simplified' version returned inside an Audiobook
}

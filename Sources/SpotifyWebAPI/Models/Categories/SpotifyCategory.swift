import Foundation

/// A Spotify Browse Category Object.
/// Source: GET /v1/browse/categories
public struct SpotifyCategory: Codable, Sendable, Equatable {
    public let href: URL
    public let icons: [SpotifyImage]
    public let id: String
    public let name: String
}

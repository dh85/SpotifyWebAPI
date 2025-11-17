import Foundation

/// A Spotify Browse Category Object.
/// Source: GET /v1/browse/categories
public struct Category: Codable, Sendable, Equatable {
    /// The Spotify category ID.
    public let id: String

    /// The name of the category.
    public let name: String

    /// A link to the Web API endpoint returning full details of the category.
    public let href: URL

    /// The category icon, in various sizes.
    public let icons: [SpotifyImage]
}

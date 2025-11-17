import Foundation

/// A Full Artist Object.
/// Source: GET /v1/artists/{id}
public struct Artist: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let href: URL
    public let uri: String
    public let externalUrls: SpotifyExternalUrls?
    public let followers: SpotifyFollowers?
    public let genres: [String]?
    public let images: [SpotifyImage]?
    public let popularity: Int?
}

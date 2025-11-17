import Foundation

/// A user's public profile.
/// Source: `GET /v1/users/{user_id}`
public struct PublicUserProfile: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String?
    public let href: URL
    public let uri: String
    public let externalUrls: SpotifyExternalUrls?
    public let followers: SpotifyFollowers?
    public let images: [SpotifyImage]
}

import Foundation

/// Typed model representing the authenticated user's private profile.
/// Source: GET /v1/me
public struct CurrentUserProfile: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String?
    public let email: String?
    public let country: String?
    public let product: String?
    public let href: URL?
    public let externalUrls: SpotifyExternalUrls?
    public let images: [SpotifyImage]
    public let followers: SpotifyFollowers?
    public let explicitContent: ExplicitContentSettings?

    public struct ExplicitContentSettings: Codable, Sendable, Equatable {
        public let filterEnabled: Bool?
        public let filterLocked: Bool?
    }
}

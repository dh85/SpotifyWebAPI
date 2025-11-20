import Foundation

/// The authenticated user's private profile.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile)
public struct CurrentUserProfile: Codable, Sendable, Equatable {
    /// The Spotify user ID.
    public let id: String
    /// Display name.
    public let displayName: String?
    /// Email address. Requires `user-read-email` scope.
    public let email: String?
    /// Country code (ISO 3166-1 alpha-2).
    public let country: String?
    /// Subscription level (e.g., "premium", "free").
    public let product: String?
    /// API endpoint URL for full user details.
    public let href: URL?
    /// External URLs for this user.
    public let externalUrls: SpotifyExternalUrls?
    /// Profile images.
    public let images: [SpotifyImage]
    /// Follower information.
    public let followers: SpotifyFollowers?
    /// Explicit content filter settings.
    public let explicitContent: ExplicitContentSettings?

    public struct ExplicitContentSettings: Codable, Sendable, Equatable {
        public let filterEnabled: Bool?
        public let filterLocked: Bool?
    }
}

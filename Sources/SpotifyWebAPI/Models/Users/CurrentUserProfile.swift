import Foundation

/// The authenticated user's private profile.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-current-users-profile)
public struct CurrentUserProfile: Codable, Sendable, Equatable {
  /// The Spotify user ID.
  public let id: String
  /// Display name. `nil` if not available.
  public let displayName: String?
  /// Email address. Requires `user-read-email` scope.
  public let email: String?
  /// Country code (ISO 3166-1 alpha-2). Requires `user-read-private` scope.
  public let country: String?
  /// Subscription level (e.g., "premium", "free"). Requires `user-read-private` scope.
  public let product: String?
  /// API endpoint URL for full user details.
  public let href: URL
  /// External URLs for this user.
  public let externalUrls: SpotifyExternalUrls
  /// Profile images.
  public let images: [SpotifyImage]
  /// Follower information.
  public let followers: SpotifyFollowers
  /// Explicit content filter settings. Requires `user-read-private` scope.
  public let explicitContent: ExplicitContentSettings?
  /// Object type (always "user").
  public let type: SpotifyObjectType
  /// The Spotify URI.
  public let uri: String

  /// Explicit content filter settings.
  public struct ExplicitContentSettings: Codable, Sendable, Equatable {
    /// Whether explicit content filtering is enabled.
    public let filterEnabled: Bool
    /// Whether explicit content filtering is locked.
    public let filterLocked: Bool
  }
}

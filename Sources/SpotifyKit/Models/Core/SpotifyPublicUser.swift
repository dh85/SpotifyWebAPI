import Foundation

/// A public user profile object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-users-profile)
public struct SpotifyPublicUser: Codable, Sendable, Equatable {
  /// Known public external URLs for this user.
  public let externalUrls: SpotifyExternalUrls?
  /// A link to the Web API endpoint for this user.
  public let href: URL?
  /// The Spotify user ID for this user.
  public let id: String
  /// The object type (always "user").
  public let type: SpotifyObjectType
  /// The Spotify URI for this user.
  public let uri: String
  /// The name displayed on the user's profile. Can be null.
  public let displayName: String?
}

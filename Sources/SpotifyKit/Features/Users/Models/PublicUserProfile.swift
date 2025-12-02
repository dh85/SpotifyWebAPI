import Foundation

/// A user's public profile.
/// Source: `GET /v1/users/{user_id}`
public struct PublicUserProfile: Codable, Sendable, Equatable {
    /// The Spotify user ID for the user.
    public let id: String
    
    /// The name displayed on the user's profile. `nil` if not available.
    public let displayName: String?
    
    /// A link to the Web API endpoint for this user.
    public let href: URL
    
    /// The Spotify URI for the user.
    public let uri: String
    
    /// The object type: "user".
    public let type: String
    
    /// Known external URLs for this user.
    public let externalUrls: SpotifyExternalUrls
    
    /// Information about the followers of the user.
    public let followers: SpotifyFollowers
    
    /// The user's profile image.
    public let images: [SpotifyImage]
}

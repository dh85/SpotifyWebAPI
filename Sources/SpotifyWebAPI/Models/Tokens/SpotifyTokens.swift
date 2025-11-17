import Foundation

/// Normalized access/refresh token information used by the client.
public struct SpotifyTokens: Codable, Sendable, Equatable {
    /// Short-lived access token (usually ~1 hour).
    public let accessToken: String

    /// Refresh token, if granted by Spotify for this flow.
    public let refreshToken: String?

    /// Absolute expiry timestamp for the access token.
    public let expiresAt: Date

    /// Raw scope string returned by Spotify (space-separated scopes).
    public let scope: String?

    /// Token type (typically "Bearer").
    public let tokenType: String

    /// Whether the access token is expired at the time of calling.
    public var isExpired: Bool {
        Date() >= expiresAt
    }
}

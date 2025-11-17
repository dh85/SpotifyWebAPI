import Foundation

/// Errors thrown by the high-level SpotifyClient (beyond auth-specific errors).
public enum SpotifyClientError: Error, Sendable {
    case unexpectedResponse
}

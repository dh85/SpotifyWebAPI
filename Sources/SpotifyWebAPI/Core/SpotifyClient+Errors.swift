import Foundation

/// Errors thrown by the high-level SpotifyClient (beyond auth-specific errors).
public enum SpotifyClientError: Error, Sendable {
    /// The API response could not be decoded or was unexpected.
    case unexpectedResponse

    /// The request was invalid (e.g., too many IDs provided).
    case invalidRequest(reason: String)
}

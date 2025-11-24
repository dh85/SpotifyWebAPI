import Foundation

/// Errors thrown by the high-level SpotifyClient (beyond auth-specific errors).
public enum SpotifyClientError: Error, Sendable, Equatable {
    /// The API response could not be decoded or was unexpected.
    case unexpectedResponse

    /// The request was invalid (e.g., too many IDs provided).
    case invalidRequest(reason: String)

    /// Network failure occurred during request.
    case networkFailure(String)

    /// HTTP error with status code and response body.
    case httpError(statusCode: Int, body: String)

    /// Client is in offline mode and network requests are disabled.
    case offline
}

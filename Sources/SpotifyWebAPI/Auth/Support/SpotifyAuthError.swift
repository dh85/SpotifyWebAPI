import Foundation

/// Errors related to Spotify OAuth, token refresh, HTTP responses,
/// and redirect callback handling.
public enum SpotifyAuthError: Error, Equatable, Sendable {

    // MARK: - OAuth redirect issues

    /// The `code` query item was missing from a redirect URL callback.
    case missingCode

    /// The `state` query item was missing from a redirect URL callback.
    case missingState

    /// The returned state did not match the expected CSRF state.
    case stateMismatch

    /// No usable refresh token was found, and access tokens are expired.
    case missingRefreshToken

    // MARK: - Networking / decoding issues

    /// The HTTP response was not an `HTTPURLResponse` when expected.
    case unexpectedResponse

    /// Spotify returned a non-2xx HTTP error, including the response body.
    case httpError(statusCode: Int, body: String)
}

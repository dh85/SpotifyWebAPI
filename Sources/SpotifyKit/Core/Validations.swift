import Foundation

func validateLimit(
  _ limit: Int,
  withinRange range: ClosedRange<Int> = SpotifyAPILimits.Pagination.standardLimitRange
) throws {
  guard range.contains(limit) else {
    throw SpotifyClientError.invalidRequest(
      reason: "Limit must be between \(range.lowerBound) and \(range.upperBound). You provided \(limit).",
      parameter: "limit",
      validRange: "\(range.lowerBound)...\(range.upperBound)"
    )
  }
}

func validateMaxIdCount<C: Collection>(
  _ maximum: Int,
  for ids: C
) throws where C.Element == String {
  guard ids.count <= maximum else {
    throw SpotifyClientError.invalidRequest(
      reason: "Maximum of \(maximum) IDs allowed per request. You provided \(ids.count).",
      parameter: "ids",
      validRange: "1...\(maximum)"
    )
  }
}

/// Validates that a string is a valid Spotify URI.
///
/// - Parameter uri: The URI to validate (e.g., "spotify:track:12345").
/// - Throws: `SpotifyClientError.invalidRequest` if the URI is invalid.
func validateURI(_ uri: String) throws {
  // Basic pattern: spotify:type:id or spotify:user:username:playlist:id
  // We allow alphanumeric characters, base62 IDs, and common separators like dots, underscores, and hyphens.
  // This regex checks for "spotify:" followed by at least two colon-separated components.
  let regex = /^spotify:[a-z]+:[a-zA-Z0-9._-]+(:[a-z]+:[a-zA-Z0-9._-]+)?$/

  if try regex.wholeMatch(in: uri) == nil {
    throw SpotifyClientError.invalidRequest(
      reason: "Invalid Spotify URI: '\(uri)'. Expected format like 'spotify:track:id'.",
      parameter: "uri"
    )
  }
}

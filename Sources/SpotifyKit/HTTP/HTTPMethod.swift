/// Standard HTTP methods used in REST APIs.
///
/// This enum provides type-safe HTTP method values with additional metadata
/// about each method's characteristics.
public enum HTTPMethod: String, Sendable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case patch = "PATCH"
  case head = "HEAD"
  case options = "OPTIONS"

  /// Returns true if the method technically supports an HTTP body.
  public var allowsBody: Bool {
    switch self {
    case .get, .head:
      return false
    default:
      return true
    }
  }
}

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The normalized response returned by ``HTTPClient`` implementations.
public struct HTTPResponse: Sendable {
  public let data: Data
  public let urlResponse: URLResponse
  public let metrics: URLSessionTaskMetrics?

  public init(
    data: Data,
    response: URLResponse,
    metrics: URLSessionTaskMetrics? = nil
  ) {
    self.data = data
    self.urlResponse = response
    self.metrics = metrics
  }

  /// Convenience access to the typed HTTP response.
  public var httpURLResponse: HTTPURLResponse? {
    urlResponse as? HTTPURLResponse
  }

  public var statusCode: Int? {
    httpURLResponse?.statusCode
  }

  public var headerFields: [AnyHashable: Any]? {
    httpURLResponse?.allHeaderFields
  }
}

// MARK: - Status Code Helpers

extension HTTPResponse {
  /// Returns true if the status code indicates success (2xx).
  public var isSuccess: Bool {
    guard let code = statusCode else { return false }
    return (200..<300).contains(code)
  }

  /// Returns true if the status code indicates a client error (4xx).
  public var isClientError: Bool {
    guard let code = statusCode else { return false }
    return (400..<500).contains(code)
  }

  /// Returns true if the status code indicates a server error (5xx).
  public var isServerError: Bool {
    guard let code = statusCode else { return false }
    return (500..<600).contains(code)
  }

  /// Returns true if the status code indicates an error (4xx or 5xx).
  public var isError: Bool {
    isClientError || isServerError
  }

  /// Returns the status code range category.
  public var statusCodeRange: StatusCodeRange? {
    guard let code = statusCode else { return nil }
    switch code {
    case 100..<200: return .informational
    case 200..<300: return .success
    case 300..<400: return .redirection
    case 400..<500: return .clientError
    case 500..<600: return .serverError
    default: return nil
    }
  }

  /// Retrieves a header value by name (case-insensitive).
  /// - Parameter name: The header name (e.g., "Content-Type", "Retry-After")
  /// - Returns: The header value as a String, or nil if not found
  public func header(named name: String) -> String? {
    guard let fields = headerFields else { return nil }
    // HTTP headers are case-insensitive
    let lowercasedName = name.lowercased()
    for (key, value) in fields {
      if let keyString = key as? String,
        keyString.lowercased() == lowercasedName
      {
        return value as? String
      }
    }
    return nil
  }

  /// Retrieves a header value as an Int (useful for Content-Length, Retry-After, etc.).
  public func headerInt(named name: String) -> Int? {
    guard let value = header(named: name) else { return nil }
    return Int(value)
  }
}

/// HTTP status code range categories.
public enum StatusCodeRange: Sendable {
  case informational  // 1xx
  case success  // 2xx
  case redirection  // 3xx
  case clientError  // 4xx
  case serverError  // 5xx
}

/// Transport-level abstraction so you can stub or swap the HTTP layer.
///
/// The default implementation uses URLSession.
public protocol HTTPClient: Sendable {
  func data(for request: URLRequest) async throws -> HTTPResponse
}

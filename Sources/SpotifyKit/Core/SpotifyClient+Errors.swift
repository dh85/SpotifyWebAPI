import Foundation

/// Errors thrown by the high-level SpotifyClient (beyond auth-specific errors).
public enum SpotifyClientError: Error, Sendable, Equatable {
  /// The API response could not be decoded or was unexpected.
  case unexpectedResponse

  /// The request was invalid (e.g., too many IDs provided).
  case invalidRequest(reason: String, parameter: String? = nil, validRange: String? = nil)

  /// Network failure occurred during request.
  case networkFailure(String)

  /// HTTP error with status code and response body.
  case httpError(statusCode: Int, body: String)

  /// Client is in offline mode and network requests are disabled.
  case offline
  
  /// Whether this error is retryable.
  public var isRetryable: Bool {
    switch self {
    case .networkFailure:
      return true
    case .httpError(let statusCode, _):
      return statusCode >= 500 || statusCode == 429
    case .unexpectedResponse, .invalidRequest, .offline:
      return false
    }
  }
  
  /// Human-readable error description with context.
  public var errorDescription: String {
    switch self {
    case .unexpectedResponse:
      return "The API response was unexpected or could not be decoded."
      
    case .invalidRequest(let reason, let parameter, let validRange):
      var message = "Invalid request: \(reason)"
      if let param = parameter {
        message += " (parameter: \(param)"
        if let range = validRange {
          message += ", valid range: \(range)"
        }
        message += ")"
      }
      return message
      
    case .networkFailure(let message):
      return "Network failure: \(message). Check your internet connection and try again."
      
    case .httpError(let statusCode, let body):
      let statusMessage: String
      switch statusCode {
      case 400:
        statusMessage = "Bad Request - The request was invalid."
      case 401:
        statusMessage = "Unauthorized - Authentication required or token expired."
      case 403:
        statusMessage = "Forbidden - You don't have permission for this action."
      case 404:
        statusMessage = "Not Found - The requested resource doesn't exist."
      case 429:
        statusMessage = "Rate Limited - Too many requests. Please wait before retrying."
      case 500...599:
        statusMessage = "Server Error - Spotify's servers are experiencing issues."
      default:
        statusMessage = "HTTP Error \(statusCode)"
      }
      return "\(statusMessage)\(body.isEmpty ? "" : " Details: \(body)")"
      
    case .offline:
      return "Client is in offline mode. Network requests are disabled."
    }
  }
  
  /// Suggested retry strategy.
  public var retryStrategy: RetryStrategy {
    switch self {
    case .networkFailure:
      return .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
      
    case .httpError(let statusCode, _):
      switch statusCode {
      case 429:
        return .rateLimitBackoff
      case 500...599:
        return .exponentialBackoff(maxRetries: 3, baseDelay: 2.0)
      default:
        return .doNotRetry
      }
      
    case .unexpectedResponse, .invalidRequest, .offline:
      return .doNotRetry
    }
  }
}

/// Retry strategy for handling errors.
public enum RetryStrategy: Sendable, Equatable {
  /// Do not retry this error.
  case doNotRetry
  
  /// Retry with exponential backoff.
  case exponentialBackoff(maxRetries: Int, baseDelay: TimeInterval)
  
  /// Retry after rate limit reset (check Retry-After header).
  case rateLimitBackoff
  
  /// Human-readable description.
  public var description: String {
    switch self {
    case .doNotRetry:
      return "This error should not be retried."
    case .exponentialBackoff(let maxRetries, let baseDelay):
      return "Retry up to \(maxRetries) times with exponential backoff starting at \(baseDelay)s."
    case .rateLimitBackoff:
      return "Wait for rate limit reset before retrying (check Retry-After header)."
    }
  }
}

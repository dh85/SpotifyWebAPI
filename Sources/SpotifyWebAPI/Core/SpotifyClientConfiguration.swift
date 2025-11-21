import Foundation

/// Configuration options for SpotifyClient behavior.
public struct SpotifyClientConfiguration: Sendable {
    /// Request timeout in seconds. Default is 30 seconds.
    public let requestTimeout: TimeInterval
    
    /// Maximum number of retry attempts for rate limit (429) errors. Default is 1.
    public let maxRateLimitRetries: Int
    
    /// Custom HTTP headers to include in all requests.
    public let customHeaders: [String: String]
    
    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - requestTimeout: Request timeout in seconds. Default is 30.
    ///   - maxRateLimitRetries: Maximum retry attempts for 429 errors. Default is 1.
    ///   - customHeaders: Custom headers to include in all requests. Default is empty.
    public init(
        requestTimeout: TimeInterval = 30,
        maxRateLimitRetries: Int = 1,
        customHeaders: [String: String] = [:]
    ) {
        self.requestTimeout = requestTimeout
        self.maxRateLimitRetries = maxRateLimitRetries
        self.customHeaders = customHeaders
    }
    
    /// Default configuration.
    public static let `default` = SpotifyClientConfiguration()
}

import Foundation

/// Configuration options for SpotifyClient behavior.
public struct SpotifyClientConfiguration: Sendable {
    /// Request timeout in seconds. Default is 30 seconds.
    public let requestTimeout: TimeInterval
    
    /// Maximum number of retry attempts for rate limit (429) errors. Default is 1.
    public let maxRateLimitRetries: Int
    
    /// Network recovery configuration for handling failures.
    public let networkRecovery: NetworkRecoveryConfiguration
    
    /// Custom HTTP headers to include in all requests.
    public let customHeaders: [String: String]
    
    /// Debug configuration for logging and monitoring.
    public let debug: DebugConfiguration
    
    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - requestTimeout: Request timeout in seconds. Default is 30.
    ///   - maxRateLimitRetries: Maximum retry attempts for 429 errors. Default is 1.
    ///   - networkRecovery: Network recovery configuration. Default is enabled.
    ///   - customHeaders: Custom headers to include in all requests. Default is empty.
    public init(
        requestTimeout: TimeInterval = 30,
        maxRateLimitRetries: Int = 1,
        networkRecovery: NetworkRecoveryConfiguration = .default,
        customHeaders: [String: String] = [:],
        debug: DebugConfiguration = .disabled
    ) {
        self.requestTimeout = requestTimeout
        self.maxRateLimitRetries = maxRateLimitRetries
        self.networkRecovery = networkRecovery
        self.customHeaders = customHeaders
        self.debug = debug
    }
    
    /// Default configuration.
    public static let `default` = SpotifyClientConfiguration()
}

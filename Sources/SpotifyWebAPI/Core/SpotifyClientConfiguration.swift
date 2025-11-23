import Foundation

public enum SpotifyClientConfigurationError: Error, CustomStringConvertible {
    case nonPositiveRequestTimeout(TimeInterval)
    case negativeRateLimitRetries(Int)
    case invalidCustomHeader(String)
    case insecureAPIBaseURL(URL)
    case networkRecovery(NetworkRecoveryConfigurationError)

    public var description: String {
        switch self {
        case .nonPositiveRequestTimeout(let timeout):
            return "requestTimeout must be > 0 (received \(timeout))"
        case .negativeRateLimitRetries(let retries):
            return "maxRateLimitRetries must be >= 0 (received \(retries))"
        case .invalidCustomHeader(let name):
            return "Custom header name is invalid: \(name)"
        case .insecureAPIBaseURL(let url):
            return "apiBaseURL must use HTTPS unless targeting localhost (received \(url.absoluteString))"
        case .networkRecovery(let error):
            return "NetworkRecoveryConfiguration invalid: \(error.description)"
        }
    }
}

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

    /// Base URL for all Spotify Web API requests. Defaults to the official API host.
    public let apiBaseURL: URL

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - requestTimeout: Request timeout in seconds. Default is 30.
    ///   - maxRateLimitRetries: Maximum retry attempts for 429 errors. Default is 1.
    ///   - networkRecovery: Network recovery configuration. Default is enabled.
    ///   - customHeaders: Custom headers to include in all requests. Default is empty.
    ///   - debug: Debug logging configuration. Default is disabled.
    ///   - apiBaseURL: Override the Spotify API base URL (useful for integration tests).
    public init(
        requestTimeout: TimeInterval = 30,
        maxRateLimitRetries: Int = 1,
        networkRecovery: NetworkRecoveryConfiguration = .default,
        customHeaders: [String: String] = [:],
        debug: DebugConfiguration = .disabled,
        apiBaseURL: URL = URL(string: "https://api.spotify.com/v1")!
    ) {
        self.requestTimeout = requestTimeout
        self.maxRateLimitRetries = maxRateLimitRetries
        self.networkRecovery = networkRecovery
        self.customHeaders = customHeaders
        self.debug = debug
        self.apiBaseURL = apiBaseURL
    }

    /// Default configuration.
    public static let `default` = SpotifyClientConfiguration()
}

public extension SpotifyClientConfiguration {
    func validate() throws {
        guard requestTimeout > 0 else {
            throw SpotifyClientConfigurationError.nonPositiveRequestTimeout(requestTimeout)
        }

        guard maxRateLimitRetries >= 0 else {
            throw SpotifyClientConfigurationError.negativeRateLimitRetries(maxRateLimitRetries)
        }

        for header in customHeaders.keys {
            guard isValidHeaderName(header) else {
                throw SpotifyClientConfigurationError.invalidCustomHeader(header)
            }
        }

        guard let scheme = apiBaseURL.scheme?.lowercased(), !scheme.isEmpty else {
            throw SpotifyClientConfigurationError.insecureAPIBaseURL(apiBaseURL)
        }

        if scheme != "https" && !apiBaseURL.isLocalhost {
            throw SpotifyClientConfigurationError.insecureAPIBaseURL(apiBaseURL)
        }

        do {
            try networkRecovery.validate()
        } catch let error as NetworkRecoveryConfigurationError {
            throw SpotifyClientConfigurationError.networkRecovery(error)
        }
    }

    func validated() throws -> SpotifyClientConfiguration {
        try validate()
        return self
    }
}

private func isValidHeaderName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return !trimmed.contains(where: { $0.isNewline })
}

private extension URL {
    var isLocalhost: Bool {
        guard let host else { return false }
        let normalized = host.lowercased()
        return normalized == "localhost" || normalized == "127.0.0.1" || normalized == "::1"
    }
}

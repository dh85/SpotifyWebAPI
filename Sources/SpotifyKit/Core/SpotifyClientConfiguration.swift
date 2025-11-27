import Foundation

public enum SpotifyClientConfigurationError: Error, CustomStringConvertible {
    case nonPositiveRequestTimeout(TimeInterval)
    case negativeRateLimitRetries(Int)
    case invalidCustomHeader(String)
    case restrictedCustomHeader(String)
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
        case .restrictedCustomHeader(let name):
            return "Custom header cannot override protected header: \(name)"
        case .insecureAPIBaseURL(let url):
            return
                "apiBaseURL must use HTTPS unless targeting localhost (received \(url.absoluteString))"
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

    /// Whether identical concurrent requests should be deduplicated.
    let requestDeduplicationEnabled: Bool

    /// Custom HTTP headers to include in all requests.
    ///
    /// Certain security-sensitive headers (for example `Authorization`, `Host`, and `Cookie`)
    /// cannot be overridden via this mechanism. Use ``settingCustomHeader(name:value:)`` to add
    /// new headers safely.
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
        customHeaders: consuming [String: String] = [:],
        debug: DebugConfiguration = .disabled,
        apiBaseURL: URL = URL(string: "https://api.spotify.com/v1")!
    ) {
        self.init(
            requestTimeout: requestTimeout,
            maxRateLimitRetries: maxRateLimitRetries,
            networkRecovery: networkRecovery,
            requestDeduplicationEnabled: true,
            customHeaders: customHeaders,
            debug: debug,
            apiBaseURL: apiBaseURL
        )
    }

    /// Internal initializer that allows tests to toggle request deduplication.
    init(
        requestTimeout: TimeInterval = 30,
        maxRateLimitRetries: Int = 1,
        networkRecovery: NetworkRecoveryConfiguration = .default,
        requestDeduplicationEnabled: Bool,
        customHeaders: consuming [String: String] = [:],
        debug: DebugConfiguration = .disabled,
        apiBaseURL: URL = URL(string: "https://api.spotify.com/v1")!
    ) {
        self.requestTimeout = requestTimeout
        self.maxRateLimitRetries = maxRateLimitRetries
        self.networkRecovery = networkRecovery
        self.requestDeduplicationEnabled = requestDeduplicationEnabled
        self.customHeaders = customHeaders
        self.debug = debug
        self.apiBaseURL = apiBaseURL
    }

    /// Default configuration.
    public static let `default` = SpotifyClientConfiguration()
}

// MARK: - Fluent Modifiers

extension SpotifyClientConfiguration {

    /// Internal helper that preserves immutability while copying selective fields.
    fileprivate func copy(
        requestTimeout: TimeInterval? = nil,
        maxRateLimitRetries: Int? = nil,
        networkRecovery: NetworkRecoveryConfiguration? = nil,
        requestDeduplicationEnabled: Bool? = nil,
        customHeaders: [String: String]? = nil,
        debug: DebugConfiguration? = nil,
        apiBaseURL: URL? = nil
    ) -> SpotifyClientConfiguration {
        SpotifyClientConfiguration(
            requestTimeout: requestTimeout ?? self.requestTimeout,
            maxRateLimitRetries: maxRateLimitRetries ?? self.maxRateLimitRetries,
            networkRecovery: networkRecovery ?? self.networkRecovery,
            requestDeduplicationEnabled: requestDeduplicationEnabled
                ?? self.requestDeduplicationEnabled,
            customHeaders: customHeaders ?? self.customHeaders,
            debug: debug ?? self.debug,
            apiBaseURL: apiBaseURL ?? self.apiBaseURL
        )
    }

    /// Returns a copy of the configuration with a new request timeout.
    public func withRequestTimeout(_ timeout: TimeInterval) -> SpotifyClientConfiguration {
        copy(requestTimeout: timeout)
    }

    /// Returns a copy of the configuration with a new rate-limit retry budget.
    public func withMaxRateLimitRetries(_ retries: Int) -> SpotifyClientConfiguration {
        copy(maxRateLimitRetries: retries)
    }

    /// Returns a copy with the provided network recovery configuration.
    public func withNetworkRecovery(
        _ configuration: NetworkRecoveryConfiguration
    ) -> SpotifyClientConfiguration {
        copy(networkRecovery: configuration)
    }

    /// Returns a copy with a modified debug configuration.
    public func withDebug(_ configuration: DebugConfiguration) -> SpotifyClientConfiguration {
        copy(debug: configuration)
    }

    /// Returns a copy with a new base URL (useful for local servers or mock APIs).
    public func withAPIBaseURL(_ url: URL) -> SpotifyClientConfiguration {
        copy(apiBaseURL: url)
    }

    /// Returns a copy with custom headers replaced by the provided dictionary.
    public func withCustomHeaders(_ headers: [String: String]) -> SpotifyClientConfiguration {
        copy(customHeaders: headers)
    }

    /// Returns a copy with the specified custom headers merged into the existing dictionary.
    /// Existing keys are overwritten by the incoming values.
    public func mergingCustomHeaders(
        _ headers: [String: String]
    ) -> SpotifyClientConfiguration {
        guard !headers.isEmpty else { return self }
        var merged = customHeaders
        for (key, value) in headers { merged[key] = value }
        return copy(customHeaders: merged)
    }
}

extension SpotifyClientConfiguration {
    public func validate() throws {
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
            guard !Self.isProtectedCustomHeader(header) else {
                throw SpotifyClientConfigurationError.restrictedCustomHeader(header)
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

    public func validated() throws -> SpotifyClientConfiguration {
        try validate()
        return self
    }
}

extension SpotifyClientConfiguration {
    private static let protectedCustomHeaderNames: Set<String> = [
        "authorization",
        "proxy-authorization",
        "cookie",
        "set-cookie",
        "host",
    ]

    private static func normalizedHeaderName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    fileprivate static func isProtectedCustomHeader(_ name: String) -> Bool {
        protectedCustomHeaderNames.contains(normalizedHeaderName(name))
    }

    /// Returns a copy of the configuration with the specified header added, rejecting attempts to
    /// override protected headers.
    public func settingCustomHeader(name: String, value: String) throws
        -> SpotifyClientConfiguration
    {
        guard isValidHeaderName(name) else {
            throw SpotifyClientConfigurationError.invalidCustomHeader(name)
        }
        guard !Self.isProtectedCustomHeader(name) else {
            throw SpotifyClientConfigurationError.restrictedCustomHeader(name)
        }

        var headers = customHeaders
        headers[name] = value

        return copy(customHeaders: headers)
    }
}

private func isValidHeaderName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    return !trimmed.contains(where: { $0.isNewline })
}

extension URL {
    fileprivate var isLocalhost: Bool {
        guard let host else { return false }
        let normalized = host.lowercased()
        return normalized == "localhost" || normalized == "127.0.0.1" || normalized == "::1"
    }
}

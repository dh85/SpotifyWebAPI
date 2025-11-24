import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Tunable configuration for ``URLSessionHTTPClient``.
public struct URLSessionHTTPClientConfiguration: Sendable {
    public var timeoutIntervalForRequest: TimeInterval
    public var timeoutIntervalForResource: TimeInterval
    public var allowsCellularAccess: Bool
    public var cachePolicy: NSURLRequest.CachePolicy
    public var httpAdditionalHeaders: [String: String]

    public init(
        timeoutIntervalForRequest: TimeInterval = 30,
        timeoutIntervalForResource: TimeInterval = 60,
        allowsCellularAccess: Bool = true,
        cachePolicy: NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
        httpAdditionalHeaders: [String: String] = [:]
    ) {
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
        self.allowsCellularAccess = allowsCellularAccess
        self.cachePolicy = cachePolicy
        self.httpAdditionalHeaders = httpAdditionalHeaders
    }
}

// MARK: - Builder Pattern Methods

extension URLSessionHTTPClientConfiguration {
    /// Returns a new configuration with the specified request timeout.
    public func withRequestTimeout(_ interval: TimeInterval) -> Self {
        var config = self
        config.timeoutIntervalForRequest = interval
        return config
    }

    /// Returns a new configuration with the specified resource timeout.
    public func withResourceTimeout(_ interval: TimeInterval) -> Self {
        var config = self
        config.timeoutIntervalForResource = interval
        return config
    }

    /// Returns a new configuration with the specified cellular access setting.
    public func withCellularAccess(_ allowed: Bool) -> Self {
        var config = self
        config.allowsCellularAccess = allowed
        return config
    }

    /// Returns a new configuration with the specified cache policy.
    public func withCachePolicy(_ policy: NSURLRequest.CachePolicy) -> Self {
        var config = self
        config.cachePolicy = policy
        return config
    }

    /// Returns a new configuration with the specified additional headers.
    public func withHeaders(_ headers: [String: String]) -> Self {
        var config = self
        config.httpAdditionalHeaders = headers
        return config
    }

    /// Returns a new configuration with an additional header added.
    public func withHeader(name: String, value: String) -> Self {
        var config = self
        config.httpAdditionalHeaders[name] = value
        return config
    }
}

/// Default HTTP client backed by URLSession.
public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = URLSessionHTTPClient.makeDefaultSession()) {
        self.session = session
    }

    public init(
        configuration: URLSessionHTTPClientConfiguration,
        delegateQueue: OperationQueue? = nil,
        sessionFactory: @Sendable (URLSessionConfiguration, OperationQueue?) -> URLSession = {
            config, queue in
            URLSession(configuration: config, delegate: nil, delegateQueue: queue)
        }
    ) {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
        sessionConfiguration.timeoutIntervalForResource = configuration.timeoutIntervalForResource
        sessionConfiguration.allowsCellularAccess = configuration.allowsCellularAccess
        sessionConfiguration.requestCachePolicy = configuration.cachePolicy
        if !configuration.httpAdditionalHeaders.isEmpty {
            sessionConfiguration.httpAdditionalHeaders = configuration.httpAdditionalHeaders
        }
        self.session = sessionFactory(sessionConfiguration, delegateQueue)
    }

    public func data(for request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        return HTTPResponse(data: data, response: response)
    }

    public static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        return URLSession(configuration: configuration)
    }
}

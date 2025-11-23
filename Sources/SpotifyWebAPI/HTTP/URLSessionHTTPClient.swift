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

/// Default HTTP client backed by URLSession.
public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public init(
        configuration: URLSessionHTTPClientConfiguration,
        delegateQueue: OperationQueue? = nil,
        sessionFactory: @Sendable (URLSessionConfiguration, OperationQueue?) -> URLSession = { config, queue in
            URLSession(configuration: config, delegate: nil, delegateQueue: queue)
        }
    ) {
        let sessionConfiguration = URLSessionConfiguration.default
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
}

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

/// Transport-level abstraction so you can stub or swap the HTTP layer.
///
/// The default implementation uses URLSession.
public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse
}

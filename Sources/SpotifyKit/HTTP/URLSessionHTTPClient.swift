import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

#if canImport(Security)
    import Security
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

public enum URLSessionHTTPClientPinningError: Error, LocalizedError, Sendable {
    case certificateResourceMissing(name: String, fileExtension: String?)
    case emptyCertificateList

    public var errorDescription: String? {
        switch self {
        case let .certificateResourceMissing(name, fileExtension):
            if let fileExtension {
                return "Certificate resource \(name).\(fileExtension) could not be located."
            }
            return "Certificate resource \(name) could not be located."
        case .emptyCertificateList:
            return "At least one pinned certificate is required to enable TLS pinning."
        }
    }
}

extension URLSessionHTTPClient {
    /// Container for certificate data used when configuring TLS pinning.
    public struct PinnedCertificate: Sendable, Hashable {
        public let data: Data

        public init(data: Data) {
            self.data = data
        }

        public init(fileURL: URL) throws {
            self.init(data: try Data(contentsOf: fileURL))
        }

        public init(resource name: String, fileExtension: String?, bundle: Bundle = .main) throws {
            guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
                throw URLSessionHTTPClientPinningError.certificateResourceMissing(
                    name: name,
                    fileExtension: fileExtension
                )
            }
            try self.init(fileURL: url)
        }
    }
}

#if canImport(Security)
extension URLSessionHTTPClient {
    /// Creates a URLSession configured with certificate pinning enforced by ``URLSessionHTTPClient``.
    /// - Parameters:
    ///   - configuration: Base HTTP client configuration to apply to the session.
    ///   - pinnedCertificates: Certificates (DER data) that should be accepted during TLS validation.
    ///   - allowsSelfSignedCertificates: When true, skips default trust chain evaluation to allow
    ///     self-signed certificates that still match one of the pinned entries.
    ///   - delegateQueue: Optional queue for URLSession delegate callbacks.
    /// - Returns: A URLSession instance wired up with pinning enforcement.
    /// - Throws: ``URLSessionHTTPClientPinningError`` when certificates are missing or invalid.
    public static func makePinnedSession(
        configuration: URLSessionHTTPClientConfiguration = .init(),
        pinnedCertificates: [PinnedCertificate],
        allowsSelfSignedCertificates: Bool = false,
        delegateQueue: OperationQueue? = nil
    ) throws -> URLSession {
        guard !pinnedCertificates.isEmpty else {
            throw URLSessionHTTPClientPinningError.emptyCertificateList
        }

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest
        sessionConfiguration.timeoutIntervalForResource = configuration.timeoutIntervalForResource
        sessionConfiguration.allowsCellularAccess = configuration.allowsCellularAccess
        sessionConfiguration.requestCachePolicy = configuration.cachePolicy
        if !configuration.httpAdditionalHeaders.isEmpty {
            sessionConfiguration.httpAdditionalHeaders = configuration.httpAdditionalHeaders
        }

        let delegate = PinnedCertificateSessionDelegate(
            pinnedCertificates: Set(pinnedCertificates.map(\.data)),
            evaluateSystemTrust: !allowsSelfSignedCertificates
        )

        return URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)
    }
}

private final class PinnedCertificateSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificates: Set<Data>
    private let evaluateSystemTrust: Bool

    init(pinnedCertificates: Set<Data>, evaluateSystemTrust: Bool) {
        self.pinnedCertificates = pinnedCertificates
        self.evaluateSystemTrust = evaluateSystemTrust
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if evaluateSystemTrust {
            var evaluateError: CFError?
            guard SecTrustEvaluateWithError(serverTrust, &evaluateError) else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }

        for certificate in certificates(for: serverTrust) {
            let certificateData = SecCertificateCopyData(certificate) as Data
            if pinnedCertificates.contains(certificateData) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private func certificates(for serverTrust: SecTrust) -> [SecCertificate] {
        (SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate]) ?? []
    }
}
#endif

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// A simple HTTP client you can feed canned responses for unit tests.
///
/// Unlike ad-hoc mocks sprinkled throughout the tests, this version lives in
/// the library so consumers can inject deterministic responses without pulling
/// in the entire Spotify client stack.
public actor MockHTTPClient: HTTPClient {

    private enum Behavior {
        case success(HTTPResponse)
        case failure(Error)
    }

    private var queue: [Behavior] = []
    public private(set) var requests: [URLRequest] = []

    public init() {}

    public func addMockResponse(
        data: Data = Data(),
        statusCode: Int,
        url: URL = URL(string: "https://api.spotify.com")!,
        headers: [String: String] = [:]
    ) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        let httpResponse = HTTPResponse(data: data, response: response)
        queue.append(.success(httpResponse))
    }

    public func enqueue(_ response: HTTPResponse) {
        queue.append(.success(response))
    }

    public func addNetworkError(_ code: URLError.Code) {
        queue.append(.failure(URLError(code)))
    }

    public func addError(_ error: Error) {
        queue.append(.failure(error))
    }

    public func reset() {
        queue.removeAll()
        requests.removeAll()
    }

    public func data(for request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)

        guard !queue.isEmpty else {
            throw URLError(.cannotConnectToHost)
        }

        let behavior = queue.removeFirst()
        switch behavior {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

public extension MockHTTPClient {
    var firstRequest: URLRequest? { requests.first }
}

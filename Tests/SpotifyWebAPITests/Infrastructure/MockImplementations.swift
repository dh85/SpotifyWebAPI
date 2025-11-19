import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

actor MockHTTPClient: HTTPClient {

    /// A queue of (Data, URLResponse) tuples to be returned by `data(for:)`.
    var responseQueue: [(Data, URLResponse)] = []

    /// A log of all requests that were sent to this client.
    var requests: [URLRequest] = []

    /// A helper to create and add a mock HTTP response to the queue.
    func addMockResponse(
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
        responseQueue.append((data, response))
    }

    /// Conforms to `HTTPClient`. Records the request and returns the next
    /// response from the front of the `responseQueue`.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        guard !responseQueue.isEmpty else {
            let message =
                "MockHTTPClient: No mock response provided for request: \(request.url?.absoluteString ?? "unknown URL")"
            Issue.record(Comment(stringLiteral: message))
            throw URLError(.cannotConnectToHost)
        }

        return responseQueue.removeFirst()
    }
}

extension MockHTTPClient {
    var firstRequest: URLRequest? {
        requests.first
    }
}

/// A mock implementation of `TokenGrantAuthenticator` for testing.
actor MockTokenAuthenticator: TokenGrantAuthenticator {

    private var token: SpotifyTokens
    var didInvalidatePrevious: Bool = false

    init(token: SpotifyTokens) {
        self.token = token
    }

    func setToken(_ newToken: SpotifyTokens) {
        self.token = newToken
    }

    /// Conforms to `TokenGrantAuthenticator`.
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
        self.didInvalidatePrevious = invalidatingPrevious

        // --- THIS IS THE FIX ---

        // 1. If the client is telling us the last token was bad (401),
        //    then we must return a fresh one.
        if invalidatingPrevious {
            let refreshedToken = SpotifyTokens.mockValid
            self.token = refreshedToken  // Update internal state
            return refreshedToken
        }

        // 2. Otherwise (if invalidatingPrevious is false), we just return
        //    whatever token we're currently holding, even if it's expired.
        //    This simulates returning a cached token.
        return token
    }

    // (We don't need to implement loadPersistedTokens for these tests)
    func loadPersistedTokens() async throws -> SpotifyTokens? {
        return token
    }
}

/// A custom test error
enum TestError: Error {
    case general(String)
}

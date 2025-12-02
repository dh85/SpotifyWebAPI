import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - Mock Token Store

/// In-memory token store for tests.
actor InMemoryTokenStore: TokenStore {
    enum Failure: Error, Hashable, Sendable {
        case loadFailed
        case saveFailed
        case clearFailed
    }

    private var storedTokens: SpotifyTokens?
    private var failureModes: Set<Failure>

    init(tokens: SpotifyTokens? = nil, failures: Set<Failure> = []) {
        self.storedTokens = tokens
        self.failureModes = failures
    }

    func configureFailures(_ failures: Set<Failure>) {
        self.failureModes = failures
    }

    func setFailure(_ failure: Failure, isEnabled: Bool) {
        if isEnabled {
            failureModes.insert(failure)
        } else {
            failureModes.remove(failure)
        }
    }

    func load() async throws -> SpotifyTokens? {
        if failureModes.contains(.loadFailed) {
            throw Failure.loadFailed
        }
        return storedTokens
    }

    func save(_ tokens: SpotifyTokens) async throws {
        if failureModes.contains(.saveFailed) {
            throw Failure.saveFailed
        }
        storedTokens = tokens
    }

    func clear() async throws {
        if failureModes.contains(.clearFailed) {
            throw Failure.clearFailed
        }
        storedTokens = nil
    }
}

// MARK: - Mock HTTP Clients

/// Simple one-shot HTTP client that always returns the same HTTPURLResponse.
final class SimpleMockHTTPClient: HTTPClient, @unchecked Sendable {
    enum Response {
        case success(data: Data, statusCode: Int)
        case failure(statusCode: Int, body: String)
    }

    private let response: Response
    private(set) var recordedRequests: [URLRequest] = []

    init(response: Response) {
        self.response = response
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        recordedRequests.append(request)

        let url = request.url ?? URL(string: "https://accounts.spotify.com")!

        switch response {
        case .success(let data, let statusCode):
            let http = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return HTTPResponse(data: data, response: http)

        case .failure(let statusCode, let body):
            let http = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return HTTPResponse(data: Data(body.utf8), response: http)
        }
    }
}

/// Counts HTTP invocations while introducing an artificial delay so concurrent
/// requests overlap long enough to validate coalescing behavior.
private actor HTTPCallCounter {
    private var count = 0

    func increment() {
        count += 1
    }

    func value() -> Int {
        count
    }
}

/// HTTP client that simulates a delayed network response and records its call count.
final class SlowMockHTTPClient: HTTPClient, @unchecked Sendable {
    private let responseData: Data
    private let statusCode: Int
    private let delayNanoseconds: UInt64
    private let callCounter = HTTPCallCounter()
    private let defaultURL = URL(string: "https://accounts.spotify.com")!

    init(
        responseData: Data,
        statusCode: Int = 200,
        delayNanoseconds: UInt64 = 50_000_000
    ) {
        self.responseData = responseData
        self.statusCode = statusCode
        self.delayNanoseconds = delayNanoseconds
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        await callCounter.increment()
        try await Task.sleep(nanoseconds: delayNanoseconds)

        let url = request.url ?? defaultURL
        let http = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return HTTPResponse(data: responseData, response: http)
    }

    func recordedCallCount() async -> Int {
        await callCounter.value()
    }
}

/// HTTP client that returns a non-HTTPURLResponse, to hit the `unexpectedResponse` branch.
final class NonHTTPResponseMockHTTPClient: HTTPClient, @unchecked Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse {
        let url = request.url ?? URL(string: "https://accounts.spotify.com")!
        let response = URLResponse(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        return HTTPResponse(data: Data(), response: response)
    }
}

/// HTTP client that returns an HTTPURLResponse with a UTF-8 body.
final class StatusMockHTTPClient: HTTPClient, @unchecked Sendable {
    let statusCode: Int
    let body: String

    init(statusCode: Int, body: String) {
        self.statusCode = statusCode
        self.body = body
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        let url = request.url ?? URL(string: "https://accounts.spotify.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return HTTPResponse(data: Data(body.utf8), response: response)
    }
}

/// HTTP client that returns an HTTPURLResponse with arbitrary binary data.
final class BinaryBodyMockHTTPClient: HTTPClient, @unchecked Sendable {
    let statusCode: Int
    let data: Data

    init(statusCode: Int, data: Data) {
        self.statusCode = statusCode
        self.data = data
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        let url = request.url ?? URL(string: "https://accounts.spotify.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return HTTPResponse(data: data, response: response)
    }
}

// MARK: - Sequenced HTTP Client

/// HTTP client that returns a pre-defined sequence of responses, in order.
final class SequencedMockHTTPClient: HTTPClient, @unchecked Sendable {
    struct StubResponse {
        let data: Data
        let statusCode: Int
    }

    private var responses: [StubResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [StubResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)

        guard !responses.isEmpty else {
            throw SpotifyClientError.unexpectedResponse
        }

        let stub = responses.removeFirst()
        let url = request.url ?? URL(string: "https://api.spotify.com")!
        let http = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        return HTTPResponse(data: stub.data, response: http)
    }
}

// MARK: - PKCE Test Helpers

struct FixedPKCEProvider: PKCEProvider {
    let pair: PKCEPair
    func generatePKCE() throws -> PKCEPair { pair }
}

private struct DummyPKCEProvider: PKCEProvider {
    let pair: PKCEPair
    func generatePKCE() throws -> PKCEPair { pair }
}

extension DummyPKCEProvider {
    static func forTests() -> (expected: PKCEPair, provider: PKCEProvider) {
        let expected = PKCEPair(
            verifier: "v",
            challenge: "c",
            state: "s"
        )
        let provider: PKCEProvider = DummyPKCEProvider(pair: expected)
        return (expected, provider)
    }
}

/// Builds a fake playlists page JSON payload similar to /v1/me/playlists.
func makePlaylistsPageJSON(
    offset: Int,
    limit: Int,
    total: Int,
    hasNext: Bool,
    names: [String],
    userID: String = "user123"
) -> Data {
    let itemsJSON: [[String: Any]] = names.enumerated().map { index, name in
        [
            "collaborative": false,
            "description": "Test playlist \(index + offset)",
            "external_urls": [
                "spotify":
                    "https://open.spotify.com/playlist/\(UUID().uuidString)"
            ],
            "href":
                "https://api.spotify.com/v1/playlists/playlist\(index + offset)",
            "id": "playlist\(index + offset)",
            "images": [],
            "name": name,
            "owner": [
                "id": userID,
                "display_name": "Test User",
                "href": "https://api.spotify.com/v1/users/\(userID)",
                "external_urls": [
                    "spotify": "https://open.spotify.com/user/\(userID)"
                ],
            ],
            "public": true,
            "snapshot_id": "snapshot",
            "tracks": [
                "href":
                    "https://api.spotify.com/v1/playlists/playlist\(index + offset)/tracks",
                "total": 10,
            ],
            "type": "playlist",
            "uri": "spotify:playlist:playlist\(index + offset)",
        ]
    }

    let nextURL: String? =
        hasNext
        ? "https://api.spotify.com/v1/me/playlists?offset=\(offset + limit)&limit=\(limit)"
        : nil

    let previousURL: Any =
        offset == 0
        ? NSNull()
        : "https://api.spotify.com/v1/me/playlists?offset=\(max(offset - limit, 0))&limit=\(limit)"

    let root: [String: Any] = [
        "href":
            "https://api.spotify.com/v1/me/playlists?offset=\(offset)&limit=\(limit)",
        "items": itemsJSON,
        "limit": limit,
        "next": nextURL as Any,
        "offset": offset,
        "previous": previousURL,
        "total": total,
    ]

    return try! JSONSerialization.data(withJSONObject: root, options: [])
}

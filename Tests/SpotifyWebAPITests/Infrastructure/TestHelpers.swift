import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

// MARK: - JSON Loading

/// A helper to load mock JSON data from files in the test bundle.
enum TestDataLoader {

    /// Loads a JSON file from the `Tests/Mocks` directory.
    ///
    /// - Parameters:
    ///   - file: The name of the file (e.g., "album_full.json").
    ///   - directory: The subdirectory within `Mocks/` (e.g., "Albums").
    /// - Returns: The file's contents as `Data`.
    static func load(_ name: String) throws
        -> Data
    {
        let bundle = Bundle.module

        let sanitizedName = name.replacingOccurrences(of: ".json", with: "")

        guard
            let url = bundle.url(
                forResource: sanitizedName,
                withExtension: "json"
            )
        else {
            let message =
                "Failed to find mock data file: \(sanitizedName).json"
            Issue.record(Comment(stringLiteral: message))
            throw TestError.general(message)
        }

        return try Data(contentsOf: url)
    }
}

// MARK: - Mock Models

extension SpotifyTokens {
    static let mockValid = SpotifyTokens(
        accessToken: "VALID_ACCESS_TOKEN",
        refreshToken: "VALID_REFRESH_TOKEN",
        expiresAt: Date().addingTimeInterval(3600),  // Expires in 1 hour
        scope: "playlist-read-private",
        tokenType: "Bearer"
    )

    static let mockExpired = SpotifyTokens(
        accessToken: "EXPIRED_ACCESS_TOKEN",
        refreshToken: "EXPIRED_REFRESH_TOKEN",
        expiresAt: Date().addingTimeInterval(-3600),  // Expired 1 hour ago
        scope: "playlist-read-private",
        tokenType: "Bearer"
    )
}

func decodeModel<T: Decodable>(from data: Data) throws
    -> T
{
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(T.self, from: data)
}

func encodeModel<T: Encodable>(_ model: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return try encoder.encode(model)
}

// MARK: - Test Client Factories

func extractIDs(from url: URL?) -> Set<String> {
    guard
        let query = url?.query,
        let idsPart =
            query
            .split(separator: "&")
            .first(where: { $0.hasPrefix("ids=") })
    else { return [] }

    let raw = idsPart.dropFirst("ids=".count)
    return Set(raw.split(separator: ",").map(String.init))
}

/// Helper to create a user-auth client with mocks.
@MainActor
func makeUserAuthClient(
    configuration: SpotifyClientConfiguration = .default
) -> (
    client: SpotifyClient<UserAuthCapability>,
    http: MockHTTPClient
) {
    let http = MockHTTPClient()
    let auth = MockTokenAuthenticator(token: .mockValid)
    let client = SpotifyClient<UserAuthCapability>(
        backend: auth,
        httpClient: http,
        configuration: configuration
    )
    return (client, http)
}

/// Helper to create a predictable set of IDs like "id_1", "id_2", ...
func makeIDs(prefix: String = "id_", count: Int) -> Set<String> {
    Set((1...count).map { "\(prefix)\($0)" })
}

// MARK: - Testing Framework Helpers

func makeSourceLocation(
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) -> SourceLocation {
    SourceLocation(
        fileID: String(describing: fileID),
        filePath: String(describing: filePath),
        line: Int(line),
        column: Int(column)
    )
}

// MARK: - Request Assertions

/// Assert that a request matches expected path, method, and query parameters.
func expectRequest(
    _ request: URLRequest?, path: String, method: String, queryContains: String...
) {
    #expect(request?.url?.path() == path)
    #expect(request?.httpMethod == method)
    for query in queryContains {
        #expect(request?.url?.query()?.contains(query) == true)
    }
}

/// Assert that a request has or doesn't have a market parameter.
func expectMarketParameter(_ request: URLRequest?, market: String?) {
    if let market {
        #expect(request?.url?.query()?.contains("market=\(market)") == true)
    } else {
        #expect(request?.url?.query()?.contains("market=") == false)
    }
}

/// Assert that a request uses default pagination values.
func expectPaginationDefaults(_ request: URLRequest?) {
    #expect(request?.url?.query()?.contains("limit=20") == true)
    #expect(request?.url?.query()?.contains("offset=0") == true)
}

/// Assert that a request body contains expected IDs.
func expectIDsInBody(
    _ request: URLRequest?, path: String, method: String, expectedIDs: Set<String>
) {
    expectRequest(request, path: path, method: method)
    guard let bodyData = request?.httpBody,
          let body = try? JSONDecoder().decode(IDsBody.self, from: bodyData)
    else {
        Issue.record("Failed to decode HTTP body or body was nil")
        return
    }
    #expect(body.ids == expectedIDs)
}

// MARK: - Validation Assertions

/// Assert that an operation throws limit errors for out-of-bounds values.
@MainActor
func expectLimitErrors(operation: @escaping (Int) async throws -> Void) async {
    await expectInvalidRequest(reasonEquals: "Limit must be between 1 and 50. You provided 51.") {
        try await operation(51)
    }
    await expectInvalidRequest(reasonEquals: "Limit must be between 1 and 50. You provided 0.") {
        try await operation(0)
    }
}

// MARK: - Error Assertions

/// Assert that an async operation throws `SpotifyClientError.invalidRequest`
/// with a reason **equal** to a string.
@MainActor
func expectInvalidRequest(
    reasonEquals expected: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    _ operation: @escaping () async throws -> Void
) async {
    await expectInvalidRequest(
        sourceLocation: makeSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        ),
        where: { $0 == expected },
        operation
    )
}

/// Assert that an async operation throws `SpotifyClientError.invalidRequest`
/// with a reason **containing** a substring.
@MainActor
func expectInvalidRequest(
    reasonContains substring: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping () async throws -> Void
) async {
    await expectInvalidRequest(
        sourceLocation: makeSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        ),
        where: { $0.contains(substring) },
        operation
    )
}

/// Core invalidRequest expectation helper.
@MainActor
private func expectInvalidRequest(
    sourceLocation: SourceLocation,
    where predicate: @escaping (String) -> Bool,
    _ operation: @escaping () async throws -> Void
) async {
    do {
        try await operation()
        Issue.record(
            "Expected call to fail with invalidRequest error, but it succeeded.",
            sourceLocation: sourceLocation
        )
    } catch let error as SpotifyClientError {
        guard case .invalidRequest(let reason) = error else {
            Issue.record(
                "Expected .invalidRequest, got \(error)",
                sourceLocation: sourceLocation
            )
            return
        }
        #expect(
            predicate(reason),
            "Unexpected invalidRequest reason: \(reason)",
            sourceLocation: sourceLocation
        )
    } catch {
        Issue.record(
            "Expected SpotifyClientError, got \(error)",
            sourceLocation: sourceLocation
        )
    }
}

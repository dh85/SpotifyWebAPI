import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

#if canImport(Combine)
    import Combine
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
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(model)
}

func decodeFixture<T: Decodable>(
    _ name: String,
    as type: T.Type = T.self
) throws -> T {
    try decodeModel(from: try TestDataLoader.load(name))
}

func assertFixtureEqual<T: Decodable & Equatable>(
    _ name: String,
    expected: T,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) throws {
    let decoded: T = try decodeFixture(name, as: T.self)
    #expect(
        decoded == expected,
        sourceLocation: makeSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    )
}

func expectCodableRoundTrip<T: Codable & Equatable>(
    _ value: T,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) throws {
    let data = try encodeModel(value)
    let decoded: T = try decodeModel(from: data)
    #expect(
        decoded == value,
        sourceLocation: makeSourceLocation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    )
}

#if canImport(Combine)

    enum CombineTestError: Error {
        case missingValue
    }

    @MainActor
    func awaitFirstValue<P: Publisher>(
        _ publisher: P,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async throws -> P.Output where P.Failure == Error {
        for try await value in publisher.values {
            return value
        }

        Issue.record(
            Comment(stringLiteral: "Publisher completed without emitting a value"),
            sourceLocation: makeSourceLocation(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )
        throw CombineTestError.missingValue
    }

    @MainActor
    @discardableResult
    func assertPublisherRequest<Output>(
        fixture: String,
        path: String,
        method: String,
        queryContains: [String] = [],
        statusCode: Int = 200,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        verifyRequest: ((URLRequest?) -> Void)? = nil,
        makePublisher:
            @escaping (SpotifyClient<UserAuthCapability>) async throws -> AnyPublisher<
                Output, Error
            >
    ) async throws -> Output {
        var output: Output!
        try await withMockServiceClient(
            fixture: fixture,
            statusCode: statusCode
        ) { client, http in
            let publisher = try await makePublisher(client)
            output = try await awaitFirstValue(
                publisher,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
            let request = await http.firstRequest
            expectRequest(
                request,
                path: path,
                method: method
            )
            for query in queryContains {
                #expect(request?.url?.query()?.contains(query) == true)
            }
            verifyRequest?(request)
        }
        return output
    }

    /// Asserts that a paginated publisher fetches multiple pages and merges them into
    /// a single collection of items. This helper enqueues two responses by default,
    /// executes the provided publisher, and validates the final item count.
    @MainActor
    @discardableResult
    func assertAggregatesPages<Item>(
        fixture: String,
        of type: Item.Type,
        expectedCount: Int = 2,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        configureResponses: ((MockHTTPClient) async throws -> Void)? = nil,
        verifyFirstRequest: ((URLRequest?) -> Void)? = nil,
        makePublisher:
            @escaping (SpotifyClient<UserAuthCapability>) async throws -> AnyPublisher<
                [Item], Error
            >
    ) async throws -> [Item]
    where Item: Codable & Sendable & Equatable {
        let (client, http) = makeUserAuthClient()
        if let configureResponses {
            try await configureResponses(http)
        } else {
            try await enqueueTwoPageResponses(
                fixture: fixture,
                of: Item.self,
                http: http
            )
        }

        let publisher = try await makePublisher(client)
        let items = try await awaitFirstValue(
            publisher,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        #expect(
            items.count == expectedCount,
            sourceLocation: makeSourceLocation(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )

        if let verifyFirstRequest {
            let request = await http.firstRequest
            verifyFirstRequest(request)
        }

        return items
    }

    /// Asserts that a mutation publisher sends the expected IDs in the request body
    /// while allowing callers to customize the HTTP method, path, and response.
    @MainActor
    @discardableResult
    func assertIDsMutationPublisher<Output>(
        path: String,
        method: String,
        ids: Set<String>,
        queryContains: [String] = [],
        statusCode: Int = 200,
        responseData: Data? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column,
        verifyRequest: ((URLRequest?) -> Void)? = nil,
        makePublisher:
            @escaping (SpotifyClient<UserAuthCapability>, Set<String>) async throws -> AnyPublisher<
                Output, Error
            >
    ) async throws -> Output {
        let (client, http) = makeUserAuthClient()
        if let responseData {
            await http.addMockResponse(data: responseData, statusCode: statusCode)
        } else {
            await http.addMockResponse(statusCode: statusCode)
        }

        let publisher = try await makePublisher(client, ids)
        let output = try await awaitFirstValue(
            publisher,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        let request = await http.firstRequest
        expectIDsInBody(
            request,
            path: path,
            method: method,
            expectedIDs: ids
        )
        for query in queryContains {
            #expect(request?.url?.query()?.contains(query) == true)
        }
        verifyRequest?(request)

        return output
    }

#endif

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

/// Helper to create a user auth client with access to the auth object for testing.
func makeUserAuthClientWithAuth(
    initialToken: SpotifyTokens = .mockValid,
    configuration: SpotifyClientConfiguration = .default
) -> (
    client: SpotifyClient<UserAuthCapability>,
    http: MockHTTPClient,
    auth: MockTokenAuthenticator
) {
    let http = MockHTTPClient()
    let auth = MockTokenAuthenticator(token: initialToken)
    let client = SpotifyClient<UserAuthCapability>(
        backend: auth,
        httpClient: http,
        configuration: configuration
    )
    return (client, http, auth)
}

/// Helper to create a predictable set of IDs like "id_1", "id_2", ...
func makeIDs(prefix: String = "id_", count: Int) -> Set<String> {
    Set((1...count).map { "\(prefix)\($0)" })
}

// MARK: - Paginated Response Builders

/// Builds mock `Page` JSON using items from an existing fixture.
func makePaginatedPage<Item: Codable & Sendable & Equatable>(
    fixture: String,
    of type: Item.Type,
    offset: Int,
    limit: Int = 50,
    total: Int,
    hasNext: Bool,
    extractor: ((String) throws -> Page<Item>)? = nil
) throws -> Page<Item> {
    let base: Page<Item>
    if let extractor {
        base = try extractor(fixture)
    } else {
        let data = try TestDataLoader.load(fixture)
        base = try decodeModel(from: data)
    }
    return Page<Item>(
        href: base.href,
        items: base.items,
        limit: limit,
        next: hasNext ? base.href : nil,
        offset: offset,
        previous: nil,
        total: total
    )
}

func makePaginatedResponse<Item: Codable & Sendable & Equatable>(
    fixture: String,
    of type: Item.Type,
    offset: Int,
    limit: Int = 50,
    total: Int,
    hasNext: Bool,
    extractor: ((String) throws -> Page<Item>)? = nil
) throws -> Data {
    let page: Page<Item> = try makePaginatedPage(
        fixture: fixture,
        of: type,
        offset: offset,
        limit: limit,
        total: total,
        hasNext: hasNext,
        extractor: extractor
    )
    return try encodeModel(page)
}

@discardableResult
func enqueueTwoPageResponses<Item: Codable & Sendable & Equatable>(
    fixture: String,
    of type: Item.Type,
    firstOffset: Int = 0,
    secondOffset: Int = 50,
    limit: Int = 50,
    total: Int = 3,
    http: MockHTTPClient,
    wrap: ((Page<Item>) throws -> Data)? = nil,
    extractor: ((String) throws -> Page<Item>)? = nil
) async throws -> (first: Data, second: Data) {
    let firstPage = try makePaginatedPage(
        fixture: fixture,
        of: Item.self,
        offset: firstOffset,
        limit: limit,
        total: total,
        hasNext: true,
        extractor: extractor
    )
    let secondPage = try makePaginatedPage(
        fixture: fixture,
        of: Item.self,
        offset: secondOffset,
        limit: limit,
        total: total,
        hasNext: false,
        extractor: extractor
    )
    let firstData = try wrap?(firstPage) ?? encodeModel(firstPage)
    let secondData = try wrap?(secondPage) ?? encodeModel(secondPage)
    await http.addMockResponse(data: firstData, statusCode: 200)
    await http.addMockResponse(data: secondData, statusCode: 200)
    return (firstData, secondData)
}

func collectStreamItems<Item>(
    _ stream: AsyncThrowingStream<Item, Error>
) async throws -> [Item] {
    var items: [Item] = []
    for try await item in stream {
        items.append(item)
    }
    return items
}

func collectPageOffsets<Item>(
    _ stream: AsyncThrowingStream<Page<Item>, Error>
) async throws -> [Int] {
    var offsets: [Int] = []
    for try await page in stream {
        offsets.append(page.offset)
    }
    return offsets
}

func expectSavedStreamRequest(
    _ request: URLRequest?,
    path: String,
    market: String? = nil,
    limit: Int = 50
) {
    expectRequest(request, path: path, method: "GET")
    if let market {
        expectMarketParameter(request, market: market)
    }
    #expect(request?.url?.query()?.contains("limit=\(limit)") == true)
}

/// Builds an in-memory page for ad-hoc tests without hitting fixtures.
func makeStubPage<T>(
    baseURL: URL = URL(string: "https://api.spotify.com/v1/test")!,
    limit: Int,
    offset: Int,
    total: Int = 10_000,
    items: @autoclosure () -> [T]
) -> Page<T> where T: Sendable {
    let nextOffset = offset + limit
    let nextURL =
        nextOffset < total
        ? URL(string: "\(baseURL.absoluteString)?offset=\(nextOffset)")!
        : nil
    let previousURL =
        offset == 0
        ? nil
        : URL(
            string: "\(baseURL.absoluteString)?offset=\(max(offset - limit, 0))")!

    return Page(
        href: baseURL,
        items: items(),
        limit: limit,
        next: nextURL,
        offset: offset,
        previous: previousURL,
        total: total
    )
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

/// Assert that a request has or doesn't have a country parameter.
func expectCountryParameter(_ request: URLRequest?, country: String?) {
    if let country {
        #expect(request?.url?.query()?.contains("country=\(country)") == true)
    } else {
        #expect(request?.url?.query()?.contains("country=") == false)
    }
}

/// Assert that a request has or doesn't have a locale parameter.
func expectLocaleParameter(_ request: URLRequest?, locale: String?) {
    if let locale {
        #expect(request?.url?.query()?.contains("locale=\(locale)") == true)
    } else {
        #expect(request?.url?.query()?.contains("locale=") == false)
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

// MARK: - Service Test Helpers

/// Provides a configured client and mock HTTP response for service tests.
@MainActor
func withMockServiceClient(
    fixture: String? = nil,
    statusCode: Int = 200,
    configuration: SpotifyClientConfiguration = .default,
    _ perform: (SpotifyClient<UserAuthCapability>, MockHTTPClient) async throws -> Void
) async throws {
    let (client, http) = makeUserAuthClient(configuration: configuration)
    if let fixture {
        let data = try TestDataLoader.load(fixture)
        await http.addMockResponse(data: data, statusCode: statusCode)
    }
    try await perform(client, http)
}

/// Provides service client plus loaded fixture data for reuse.
@MainActor
func withMockServiceClient(
    fixture: String? = nil,
    statusCode: Int = 200,
    configuration: SpotifyClientConfiguration = .default,
    _ perform: (SpotifyClient<UserAuthCapability>, MockHTTPClient, Data?) async throws -> Void
) async throws {
    let (client, http) = makeUserAuthClient(configuration: configuration)
    var loadedData: Data?
    if let fixture {
        let data = try TestDataLoader.load(fixture)
        loadedData = data
        await http.addMockResponse(data: data, statusCode: statusCode)
    }
    try await perform(client, http, loadedData)
}

/// Asserts that a service request uses the default pagination query params.
@MainActor
func expectDefaultPagination(
    fixture: String,
    statusCode: Int = 200,
    configuration: SpotifyClientConfiguration = .default,
    _ operation: (SpotifyClient<UserAuthCapability>) async throws -> Void
) async throws {
    try await withMockServiceClient(
        fixture: fixture,
        statusCode: statusCode,
        configuration: configuration
    ) { client, http in
        try await operation(client)
        expectPaginationDefaults(await http.firstRequest)
    }
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

/// Asserts that an operation rejects out-of-range limit values.
@MainActor
func assertLimitOutOfRange(
    _ limits: [Int] = [0, 51],
    reasonContains message: String = "Limit must be between",
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    operation: @escaping (Int) async throws -> Void
) async {
    for limit in limits {
        await expectInvalidRequest(
            reasonContains: message,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        ) {
            try await operation(limit)
        }
    }
}

/// Asserts that providing too many IDs to an operation triggers an invalid request.
@MainActor
func assertIDBatchTooLarge<IDCollection>(
    maxAllowed: Int,
    overflow: Int = 1,
    reasonContains message: String = "Maximum of",
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    buildIDs: (Int) -> IDCollection,
    operation: @MainActor @escaping (IDCollection) async throws -> Void
) async where IDCollection: Collection, IDCollection.Element == String {
    let ids = buildIDs(maxAllowed + overflow)
    await expectInvalidRequest(
        reasonContains: message,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    ) {
        try await operation(ids)
    }
}

/// Convenience overload for ID batch assertions when IDs are simple generated sets.
@MainActor
func assertIDBatchTooLarge(
    maxAllowed: Int,
    overflow: Int = 1,
    prefix: String = "id_",
    reasonContains message: String = "Maximum of",
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    operation: @MainActor @escaping (Set<String>) async throws -> Void
) async {
    await assertIDBatchTooLarge(
        maxAllowed: maxAllowed,
        overflow: overflow,
        reasonContains: message,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column,
        buildIDs: { count in makeIDs(prefix: prefix, count: count) },
        operation: operation
    )
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

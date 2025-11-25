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

/// Collects all items from an async stream.
///
/// Reduces boilerplate for stream collection tests.
func collectStreamItems<T>(
    _ stream: AsyncThrowingStream<T, any Error>
) async throws -> [T] {
    var items: [T] = []
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

/// Assert that a request contains multiple query parameters.
func expectQueryParameters(_ request: URLRequest?, contains parameters: [String]) {
    for parameter in parameters {
        #expect(request?.url?.query()?.contains(parameter) == true)
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

// MARK: - Concurrency Test Helpers

/// Actor for recording async operations in concurrency tests.
actor OffsetRecorder {
    private var offsets: [Int] = []

    func record(_ offset: Int) {
        offsets.append(offset)
    }

    func snapshot() -> [Int] {
        offsets
    }
}

/// Creates a test token with configurable parameters.
///
/// Useful for concurrency tests that need to create many tokens quickly.
func makeTestToken(
    accessToken: String = "TEST_ACCESS",
    refreshToken: String? = "TEST_REFRESH",
    expiresIn: TimeInterval = 3600,
    scope: String? = nil
) -> SpotifyTokens {
    SpotifyTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: Date().addingTimeInterval(expiresIn),
        scope: scope,
        tokenType: "Bearer"
    )
}

/// Generates multiple paginated response pages for testing pagination.
///
/// - Parameters:
///   - fixture: The JSON fixture file to use for items
///   - type: The item type to decode
///   - pageSize: Number of items per page
///   - pageCount: Number of pages to generate
///   - totalItems: Total number of items across all pages
/// - Returns: Array of encoded page data
func makeMultiplePaginatedPages<Item: Codable & Sendable & Equatable>(
    fixture: String,
    of type: Item.Type,
    pageSize: Int,
    pageCount: Int,
    totalItems: Int
) throws -> [Data] {
    var pages: [Data] = []
    for pageIndex in 0..<pageCount {
        let offset = pageIndex * pageSize
        let hasNext = (pageIndex + 1) < pageCount
        let page = try makePaginatedResponse(
            fixture: fixture,
            of: type,
            offset: offset,
            limit: pageSize,
            total: totalItems,
            hasNext: hasNext
        )
        pages.append(page)
    }
    return pages
}

/// Executes a task, waits briefly, cancels it, and asserts cancellation behavior.
///
/// - Parameters:
///   - delayBeforeCancel: How long to wait before canceling (default: 50ms)
///   - task: The task to test for cancellation
///   - expectation: What to expect from the cancelled task
func assertTaskCancellation<T: Sendable>(
    delayBeforeCancel: Duration = .milliseconds(50),
    task: Task<T, Error>,
    expectation: @escaping @Sendable (Result<T, Error>) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    try await Task.sleep(for: delayBeforeCancel)
    task.cancel()

    let result = await task.result
    #expect(expectation(result), sourceLocation: sourceLocation)
}

/// Asserts that a task result represents cancellation.
func expectCancellation<T>(
    _ result: Result<T, Error>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch result {
    case .success:
        Issue.record("Expected task to be cancelled", sourceLocation: sourceLocation)
    case .failure(let error):
        if !(error is CancellationError) {
            Issue.record("Expected CancellationError, got \(error)", sourceLocation: sourceLocation)
        }
    }
}

/// Asserts that a task result is success with an optional value check.
func expectTaskSuccess<T>(
    _ result: Result<T, Error>,
    where predicate: ((T) -> Bool)? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch result {
    case .success(let value):
        if let predicate, !predicate(value) {
            Issue.record(
                "Task succeeded but value didn't match predicate", sourceLocation: sourceLocation)
        }
    case .failure(let error):
        Issue.record("Expected success, got error: \(error)", sourceLocation: sourceLocation)
    }
}

/// Runs multiple concurrent tasks and collects their results.
///
/// - Parameters:
///   - count: Number of concurrent tasks to run
///   - operation: The operation to perform in each task
/// - Returns: Array of results from all tasks
func runConcurrentTasks<T: Sendable>(
    count: Int,
    operation: @escaping @Sendable () async throws -> T
) async throws -> [T] {
    try await withThrowingTaskGroup(of: T.self) { group in
        for _ in 0..<count {
            group.addTask {
                try await operation()
            }
        }

        var results: [T] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}

// MARK: - Core Test Helpers

/// Converts a JSON string to Data.
func makeJSONData(_ string: String) -> Data {
    string.data(using: .utf8)!
}

/// Creates a mock playlist snapshot response.
func makeSnapshotResponse(_ id: String = "snapshot123") -> Data {
    makeJSONData("{\"snapshot_id\": \"\(id)\"}")
}

/// Generates an array of test IDs with a given prefix.
func makeTestIDs(_ prefix: String, count: Int) -> [String] {
    (1...count).map { "\(prefix)\($0)" }
}

/// Creates a simple album JSON response for testing.
func makeAlbumJSON(
    id: String,
    name: String,
    artistName: String = "Test Artist",
    totalTracks: Int = 10,
    popularity: Int = 50
) -> Data {
    let json = """
        {
            "album_type": "album",
            "total_tracks": \(totalTracks),
            "available_markets": ["US", "CA"],
            "external_urls": {"spotify": "https://open.spotify.com/album/\(id)"},
            "href": "https://api.spotify.com/v1/albums/\(id)",
            "id": "\(id)",
            "images": [],
            "name": "\(name)",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "album",
            "uri": "spotify:album:\(id)",
            "artists": [{
                "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"},
                "href": "https://api.spotify.com/v1/artists/artist1",
                "id": "artist1",
                "name": "\(artistName)",
                "type": "artist",
                "uri": "spotify:artist:artist1"
            }],
            "tracks": {
                "href": "https://api.spotify.com/v1/albums/\(id)/tracks",
                "limit": 50,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": \(totalTracks),
                "items": []
            },
            "copyrights": [],
            "external_ids": {},
            "genres": [],
            "label": "Test Label",
            "popularity": \(popularity)
        }
        """
    return makeJSONData(json)
}

/// Creates a network recovery configuration for testing.
func makeRecoveryConfig(
    maxRetries: Int = 2,
    baseDelay: TimeInterval = 0.1
) -> SpotifyClientConfiguration {
    SpotifyClientConfiguration(
        networkRecovery: NetworkRecoveryConfiguration(
            maxNetworkRetries: maxRetries,
            baseRetryDelay: baseDelay
        )
    )
}

// MARK: - Reusable Test Actors

/// Generic actor for tracking events in tests.
actor EventCollector<T: Sendable> {
    private(set) var events: [T] = []
    private(set) var count: Int = 0

    func record(_ event: T) {
        events.append(event)
        count += 1
    }

    func reset() {
        events.removeAll()
        count = 0
    }
}

/// Actor for safely collecting progress reports from callbacks.
actor ProgressHolder {
    private(set) var progressReports: [BatchProgress] = []

    func add(_ progress: BatchProgress) {
        progressReports.append(progress)
    }

    func reset() {
        progressReports.removeAll()
    }
}

/// Actor for tracking token refresh events.
actor TokenRefreshTracker {
    var willStartCalled = false
    var willStartInfo: TokenRefreshInfo?
    var didSucceedCalled = false
    var succeededTokens: SpotifyTokens?
    var didFailCalled = false
    var failedError: Error?
    var callSequence: [String] = []

    func recordWillStart(_ info: TokenRefreshInfo) {
        willStartCalled = true
        willStartInfo = info
        callSequence.append("willStart")
    }

    func recordDidSucceed(_ tokens: SpotifyTokens) {
        didSucceedCalled = true
        succeededTokens = tokens
        callSequence.append("didSucceed")
    }

    func recordDidFail(_ error: Error) {
        didFailCalled = true
        failedError = error
        callSequence.append("didFail")
    }

    func reset() {
        willStartCalled = false
        willStartInfo = nil
        didSucceedCalled = false
        succeededTokens = nil
        didFailCalled = false
        failedError = nil
        callSequence = []
    }
}

/// Actor for tracking token expiration callbacks.
actor TokenExpirationTracker {
    var wasCalled = false
    var expiresIn: TimeInterval?
    var callCount = 0

    func recordExpiration(_ time: TimeInterval) {
        wasCalled = true
        expiresIn = time
        callCount += 1
    }

    func recordExpiration() {
        wasCalled = true
        callCount += 1
    }

    func reset() {
        wasCalled = false
        expiresIn = nil
        callCount = 0
    }
}

/// Actor for tracking cancellation in async operations.
actor CancellationTracker {
    private var started = false
    private var cancelled = false

    func markStarted() {
        started = true
    }

    func markCancelled() {
        cancelled = true
    }

    func waitForStart(timeout: Duration = .milliseconds(250)) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while started == false {
            if clock.now >= deadline { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return started
    }

    func waitForCancellation(timeout: Duration = .milliseconds(250)) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while cancelled == false {
            if clock.now >= deadline { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return cancelled
    }
}

/// Actor for recording fetch operations in pagination tests.
actor FetchRecorder {
    private(set) var count: Int = 0
    private var waiters: [CountWaiter] = []

    private struct CountWaiter {
        let target: Int
        let continuation: CheckedContinuation<Int, Never>
        let handler: (@Sendable (Int) -> Void)?
    }

    func record(offset: Int) {
        _ = offset
        count += 1
        fulfillWaiters()
    }

    func waitForCount(
        atLeast target: Int,
        onSatisfy: (@Sendable (Int) -> Void)? = nil
    ) async -> Int {
        if count >= target {
            onSatisfy?(count)
            return count
        }

        return await withCheckedContinuation { continuation in
            waiters.append(
                CountWaiter(
                    target: target,
                    continuation: continuation,
                    handler: onSatisfy
                )
            )
        }
    }

    private func fulfillWaiters() {
        guard !waiters.isEmpty else { return }

        var remaining: [CountWaiter] = []
        for waiter in waiters {
            if count >= waiter.target {
                waiter.continuation.resume(returning: count)
                waiter.handler?(count)
            } else {
                remaining.append(waiter)
            }
        }

        waiters = remaining
    }
}

// MARK: - Test Timing Constants

/// Standard short delay for test synchronization.
let testShortDelay: Duration = .milliseconds(10)

/// Standard medium delay for test operations.
let testMediumDelay: Duration = .milliseconds(50)

/// Standard long delay for test timeouts.
let testLongDelay: Duration = .milliseconds(100)

// MARK: - Progress Testing Helpers

/// Executes a batch operation and collects progress reports.
func withProgressTracking<T>(
    operation: (@escaping (BatchProgress) -> Void) async throws -> T
) async throws -> (result: T, progress: [BatchProgress]) {
    let holder = ProgressHolder()
    let result = try await operation { progress in
        Task {
            await holder.add(progress)
        }
    }
    let progress = await holder.progressReports
    return (result, progress)
}

// MARK: - Service Test Refactoring Helpers

/// Verifies HTTP request after async service operation.
///
/// Consolidates the common pattern of fetching firstRequest and running multiple expectations.
@MainActor
func verifyRequest(
    _ http: MockHTTPClient,
    path: String,
    method: String,
    queryContains: [String] = [],
    verifyMarket market: String? = nil,
    additionalChecks: ((URLRequest?) -> Void)? = nil
) async {
    let request = await http.firstRequest
    if queryContains.isEmpty {
        expectRequest(request, path: path, method: method)
    } else {
        expectRequest(request, path: path, method: method, queryContains: queryContains[0])
        for query in queryContains.dropFirst() {
            #expect(request?.url?.query()?.contains(query) == true)
        }
    }
    if let market {
        expectMarketParameter(request, market: market)
    }
    additionalChecks?(request)
}

/// Sets up client with a paginated response ready to use.
///
/// Combines makeUserAuthClient + makePaginatedResponse + addMockResponse into one call.
@MainActor
func makeClientWithPaginatedResponse<T: Codable & Sendable & Equatable>(
    fixture: String,
    of type: T.Type,
    offset: Int = 0,
    limit: Int = 20,
    total: Int,
    hasNext: Bool = false,
    configuration: SpotifyClientConfiguration = .default
) async throws -> (SpotifyClient<UserAuthCapability>, MockHTTPClient) {
    let (client, http) = makeUserAuthClient(configuration: configuration)
    let response = try makePaginatedResponse(
        fixture: fixture, of: type, offset: offset, limit: limit, total: total, hasNext: hasNext
    )
    await http.addMockResponse(data: response, statusCode: 200)
    return (client, http)
}

/// Enqueues multiple paginated responses for multi-page tests.
///
/// Automatically calculates page count and sets up hasNext flags correctly.
@MainActor
func enqueuePaginatedPages<T: Codable & Sendable & Equatable>(
    http: MockHTTPClient,
    fixture: String,
    of type: T.Type,
    pageSize: Int,
    totalItems: Int
) async throws {
    let pageCount = (totalItems + pageSize - 1) / pageSize
    for page in 0..<pageCount {
        let offset = page * pageSize
        let hasNext = page < pageCount - 1
        let response = try makePaginatedResponse(
            fixture: fixture, of: type,
            offset: offset, limit: pageSize, total: totalItems, hasNext: hasNext
        )
        await http.addMockResponse(data: response, statusCode: 200)
    }
}

/// Tests that an operation validates and rejects oversized ID batches.
///
/// Standardizes ID limit validation tests across all services.
@MainActor
func expectIDBatchLimit(
    max: Int,
    reasonContains: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line,
    operation: @escaping (Set<String>) async throws -> Void
) async {
    let reason = reasonContains ?? "Maximum of \(max)"
    await expectInvalidRequest(
        reasonContains: reason,
        filePath: file,
        line: line,
        operation: {
            try await operation(makeIDs(count: max + 1))
        }
    )
}

/// Tests operations that return no content (200/204 responses).
///
/// Reduces boilerplate for simple PUT/POST/DELETE operations.
@MainActor
func expectNoContentOperation(
    path: String,
    method: String,
    queryContains: String...,
    operation: () async throws -> Void
) async throws {
    let (_, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await operation()

    let request = await http.firstRequest
    if queryContains.isEmpty {
        expectRequest(request, path: path, method: method)
    } else {
        expectRequest(request, path: path, method: method, queryContains: queryContains[0])
        for query in queryContains.dropFirst() {
            #expect(request?.url?.query()?.contains(query) == true)
        }
    }
}

/// Tests that a service operation correctly includes/omits market parameter.
///
/// Consolidates parameterized market tests into a single helper.
@MainActor
func expectMarketParameterHandling(
    fixture: String,
    markets: [String?] = [nil, "US"],
    operation: (SpotifyClient<UserAuthCapability>, String?) async throws -> Void
) async throws {
    for market in markets {
        try await withMockServiceClient(fixture: fixture) { client, http in
            try await operation(client, market)
            expectMarketParameter(await http.firstRequest, market: market)
        }
    }
}

/// Tests library save/remove/check operations with ID body verification.
///
/// Common pattern for user library endpoints across albums, tracks, shows, etc.
@MainActor
func expectLibraryOperation(
    path: String,
    method: String,
    ids: Set<String>,
    operation: (Set<String>) async throws -> Void
) async throws {
    let (_, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await operation(ids)

    expectIDsInBody(
        await http.firstRequest,
        path: path,
        method: method,
        expectedIDs: ids
    )
}

#if canImport(Combine)
    import Combine

    /// Tests that a Combine publisher validates pagination limits.
    ///
    /// Standardizes limit validation for all *Publisher methods.
    @MainActor
    func expectPublisherLimitValidation<T>(
        makePublisher: @escaping (Int) -> AnyPublisher<T, Error>
    ) async {
        await assertLimitOutOfRange { limit in
            _ = try await awaitFirstValue(makePublisher(limit))
        }
    }

    /// Tests that a Combine publisher validates ID batch sizes.
    ///
    /// Standardizes ID limit validation for publisher methods.
    @MainActor
    func expectPublisherIDBatchLimit<T>(
        max: Int,
        makePublisher: @escaping (Set<String>) -> AnyPublisher<T, Error>
    ) async {
        let ids = makeIDs(count: max + 1)
        await expectInvalidRequest(reasonContains: "Maximum of \(max)") {
            _ = try await awaitFirstValue(makePublisher(ids))
        }
    }
#endif

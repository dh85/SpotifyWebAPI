import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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

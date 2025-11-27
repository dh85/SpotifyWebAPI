import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

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

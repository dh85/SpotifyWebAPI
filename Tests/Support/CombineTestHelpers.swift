import Foundation
import Testing

@testable import SpotifyKit

#if canImport(Combine)
    import Combine

    // MARK: - Combine Test Helpers

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

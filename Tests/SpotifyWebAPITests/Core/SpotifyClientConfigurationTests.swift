import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("SpotifyClientConfiguration Tests")
struct SpotifyClientConfigurationTests {

    @Test("Default configuration values")
    func defaultConfiguration() {
        let config = SpotifyClientConfiguration.default

        #expect(config.requestTimeout == 30)
        #expect(config.maxRateLimitRetries == 1)
        #expect(config.customHeaders.isEmpty)
    }

    @Test("Custom configuration values")
    func customConfiguration() {
        let config = SpotifyClientConfiguration(
            requestTimeout: 60,
            maxRateLimitRetries: 3,
            customHeaders: ["X-Custom": "value", "X-App": "test"]
        )

        #expect(config.requestTimeout == 60)
        #expect(config.maxRateLimitRetries == 3)
        #expect(config.customHeaders.count == 2)
        #expect(config.customHeaders["X-Custom"] == "value")
        #expect(config.customHeaders["X-App"] == "test")
    }

    @Test("Configuration is Sendable")
    func configurationSendable() async {
        let config = SpotifyClientConfiguration(requestTimeout: 45)

        let task = Task.detached {
            return config.requestTimeout
        }

        let timeout = await task.value
        #expect(timeout == 45)
    }

    @Test("Client uses custom timeout")
    @MainActor
    func clientUsesCustomTimeout() async throws {
        let config = SpotifyClientConfiguration(requestTimeout: 5)
        let (client, http) = makeUserAuthClient(configuration: config)

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].timeoutInterval == 5)
    }

    @Test("Client uses custom headers")
    @MainActor
    func clientUsesCustomHeaders() async throws {
        let config = SpotifyClientConfiguration(
            customHeaders: ["X-App-Version": "1.0", "X-Platform": "iOS"]
        )
        let (client, http) = makeUserAuthClient(configuration: config)

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].value(forHTTPHeaderField: "X-App-Version") == "1.0")
        #expect(requests[0].value(forHTTPHeaderField: "X-Platform") == "iOS")
    }

    @Test("Client respects maxRateLimitRetries")
    @MainActor
    func clientRespectsMaxRetries() async throws {
        let config = SpotifyClientConfiguration(maxRateLimitRetries: 3)
        let (client, http) = makeUserAuthClient(configuration: config)

        // Add 3 rate limit responses + 1 success
        for _ in 0..<3 {
            await http.addMockResponse(
                statusCode: 429,
                headers: ["Retry-After": "0"]
            )
        }
        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests.count == 4)
    }

    @Test("Client stops retrying after maxRateLimitRetries")
    @MainActor
    func clientStopsRetrying() async throws {
        let config = SpotifyClientConfiguration(maxRateLimitRetries: 2)
        let (client, http) = makeUserAuthClient(configuration: config)

        // Add 3 rate limit responses (more than max retries)
        for _ in 0..<3 {
            await http.addMockResponse(
                statusCode: 429,
                headers: ["Retry-After": "0"]
            )
        }

        do {
            _ = try await client.users.me()
            Issue.record("Expected error but succeeded")
        } catch {
            // Expected to fail after 2 retries (3 total requests)
        }

        let requests = await http.requests
        #expect(requests.count == 3)
    }

    @Test("validate rejects non-positive requestTimeout")
    func validateRejectsNonPositiveTimeout() {
        let config = SpotifyClientConfiguration(requestTimeout: 0)

        expectValidationError(config) { error in
            guard case .nonPositiveRequestTimeout(let value) = error else {
                Issue.record("Expected nonPositiveRequestTimeout, received \(error)")
                return
            }
            #expect(value == 0)
        }
    }

    @Test("validate rejects negative maxRateLimitRetries")
    func validateRejectsNegativeRetryBudget() {
        let config = SpotifyClientConfiguration(maxRateLimitRetries: -1)

        expectValidationError(config) { error in
            guard case .negativeRateLimitRetries(let retries) = error else {
                Issue.record("Expected negativeRateLimitRetries, received \(error)")
                return
            }
            #expect(retries == -1)
        }
    }

    @Test("validate rejects invalid custom header names")
    func validateRejectsInvalidHeaderNames() {
        let config = SpotifyClientConfiguration(customHeaders: ["X-Bad\nHeader": "oops"])

        expectValidationError(config) { error in
            guard case .invalidCustomHeader(let name) = error else {
                Issue.record("Expected invalidCustomHeader, received \(error)")
                return
            }
            #expect(name == "X-Bad\nHeader")
        }
    }

    @Test("validate rejects base URLs without scheme")
    func validateRejectsMissingScheme() {
        let config = SpotifyClientConfiguration(
            apiBaseURL: URL(string: "api.spotify.com/v1")!
        )

        expectValidationError(config) { error in
            guard case .insecureAPIBaseURL(let url) = error else {
                Issue.record("Expected insecureAPIBaseURL, received \(error)")
                return
            }
            #expect(url.absoluteString == "api.spotify.com/v1")
        }
    }

    @Test("validate enforces HTTPS except for localhost")
    func validateHTTPSRules() throws {
        let insecure = SpotifyClientConfiguration(
            apiBaseURL: URL(string: "http://example.com/v1")!
        )

        expectValidationError(insecure) { error in
            guard case .insecureAPIBaseURL(let url) = error else {
                Issue.record("Expected insecureAPIBaseURL, received \(error)")
                return
            }
            #expect(url.absoluteString == "http://example.com/v1")
        }

        let localhostConfig = SpotifyClientConfiguration(
            apiBaseURL: URL(string: "http://localhost:8080/v1")!
        )
        try localhostConfig.validate()
    }

    @Test("validate surfaces networkRecovery errors")
    func validateWrapsNetworkRecoveryErrors() {
        let failingRecovery = NetworkRecoveryConfiguration(baseRetryDelay: 0)
        let config = SpotifyClientConfiguration(networkRecovery: failingRecovery)

        expectValidationError(config) { error in
            guard case .networkRecovery(let recoveryError) = error,
                case .nonPositiveBaseDelay(let delay) = recoveryError
            else {
                Issue.record("Expected wrapped nonPositiveBaseDelay, received \(error)")
                return
            }
            #expect(delay == 0)
        }
    }

    @Test("validated returns configuration when valid")
    func validatedReturnsSelf() throws {
        let config = SpotifyClientConfiguration(
            requestTimeout: 45,
            customHeaders: ["X-Custom": "value"]
        )

        let validated = try config.validated()
        #expect(validated.requestTimeout == 45)
        #expect(validated.customHeaders["X-Custom"] == "value")
        #expect(validated.apiBaseURL == config.apiBaseURL)
    }

    @Test("configuration error descriptions")
    func configurationErrorDescriptions() {
        let baseURL = URL(string: "http://example.com/v1")!
        let nested = NetworkRecoveryConfigurationError.negativeRetryCount(2)

        let cases: [(SpotifyClientConfigurationError, String)] = [
            (.nonPositiveRequestTimeout(0), "requestTimeout must be > 0 (received 0.0)"),
            (.negativeRateLimitRetries(-1), "maxRateLimitRetries must be >= 0 (received -1)"),
            (.invalidCustomHeader("X-Invalid"), "Custom header name is invalid: X-Invalid"),
            (
                .insecureAPIBaseURL(baseURL),
                "apiBaseURL must use HTTPS unless targeting localhost (received http://example.com/v1)"
            ),
            (
                .networkRecovery(nested),
                "NetworkRecoveryConfiguration invalid: maxNetworkRetries must be >= 0 (received 2)"
            ),
        ]

        for (error, expected) in cases {
            #expect(error.description == expected)
        }
    }
}

private func expectValidationError(
    _ config: SpotifyClientConfiguration,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column,
    verifier: (SpotifyClientConfigurationError) -> Void
) {
    do {
        try config.validate()
        Issue.record(
            "Expected validation to fail",
            sourceLocation: makeSourceLocation(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )
    } catch let error as SpotifyClientConfigurationError {
        verifier(error)
    } catch {
        Issue.record(
            "Unexpected error: \(error)",
            sourceLocation: makeSourceLocation(
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        )
    }
}

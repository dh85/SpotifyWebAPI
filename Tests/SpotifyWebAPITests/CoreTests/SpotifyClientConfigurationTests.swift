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
}



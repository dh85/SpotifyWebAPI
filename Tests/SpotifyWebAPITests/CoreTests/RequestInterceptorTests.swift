import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Request Interceptor Tests")
struct RequestInterceptorTests {

    @Test("Interceptor can modify request")
    @MainActor
    func interceptorModifiesRequest() async throws {
        let (client, http) = makeUserAuthClient()

        await client.addInterceptor { request in
            var modified = request
            modified.setValue("CustomValue", forHTTPHeaderField: "X-Custom")
            return modified
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].value(forHTTPHeaderField: "X-Custom") == "CustomValue")
    }

    @Test("Multiple interceptors are called in order")
    @MainActor
    func multipleInterceptorsInOrder() async throws {
        let (client, http) = makeUserAuthClient()

        await client.addInterceptor { request in
            var modified = request
            modified.setValue("First", forHTTPHeaderField: "X-Order")
            return modified
        }

        await client.addInterceptor { request in
            var modified = request
            let existing = modified.value(forHTTPHeaderField: "X-Order") ?? ""
            modified.setValue(existing + ",Second", forHTTPHeaderField: "X-Order")
            return modified
        }

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].value(forHTTPHeaderField: "X-Order") == "First,Second")
    }

    @Test("Interceptor can throw error")
    @MainActor
    func interceptorThrowsError() async throws {
        let (client, _) = makeUserAuthClient()

        await client.addInterceptor { _ in
            throw TestError.general("Interceptor error")
        }

        await #expect(throws: TestError.general("Interceptor error")) {
            _ = try await client.users.me()
        }
    }

    @Test("Remove all interceptors works")
    @MainActor
    func removeAllInterceptors() async throws {
        let (client, http) = makeUserAuthClient()

        await client.addInterceptor { request in
            var modified = request
            modified.setValue("ShouldNotAppear", forHTTPHeaderField: "X-Test")
            return modified
        }

        await client.removeAllInterceptors()

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].value(forHTTPHeaderField: "X-Test") == nil)
    }

    @Test("Interceptor receives configuration headers")
    @MainActor
    func interceptorReceivesConfigHeaders() async throws {
        let config = SpotifyClientConfiguration(
            customHeaders: ["X-Config": "ConfigValue"]
        )
        let (client, http) = makeUserAuthClient(configuration: config)

        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )

        _ = try await client.users.me()

        let requests = await http.requests
        #expect(requests[0].value(forHTTPHeaderField: "X-Config") == "ConfigValue")
    }
}

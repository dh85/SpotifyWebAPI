import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("URLSessionHTTPClientConfiguration Builder Tests")
struct URLSessionHTTPClientConfigurationTests {

    @Test("withRequestTimeout returns configuration with updated timeout")
    func withRequestTimeoutUpdatesTimeout() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config.withRequestTimeout(45.0)

        #expect(updated.timeoutIntervalForRequest == 45.0)
        #expect(updated.timeoutIntervalForResource == config.timeoutIntervalForResource)
        #expect(updated.allowsCellularAccess == config.allowsCellularAccess)
        #expect(updated.cachePolicy == config.cachePolicy)
    }

    @Test("withResourceTimeout returns configuration with updated timeout")
    func withResourceTimeoutUpdatesTimeout() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config.withResourceTimeout(120.0)

        #expect(updated.timeoutIntervalForResource == 120.0)
        #expect(updated.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
        #expect(updated.allowsCellularAccess == config.allowsCellularAccess)
        #expect(updated.cachePolicy == config.cachePolicy)
    }

    @Test("withCellularAccess returns configuration with updated setting")
    func withCellularAccessUpdatesSetting() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config.withCellularAccess(false)

        #expect(updated.allowsCellularAccess == false)
        #expect(updated.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
        #expect(updated.timeoutIntervalForResource == config.timeoutIntervalForResource)
        #expect(updated.cachePolicy == config.cachePolicy)
    }

    @Test("withCachePolicy returns configuration with updated policy")
    func withCachePolicyUpdatesPolicy() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config.withCachePolicy(.returnCacheDataElseLoad)

        #expect(updated.cachePolicy == .returnCacheDataElseLoad)
        #expect(updated.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
        #expect(updated.timeoutIntervalForResource == config.timeoutIntervalForResource)
        #expect(updated.allowsCellularAccess == config.allowsCellularAccess)
    }

    @Test("withHeaders returns configuration with updated headers")
    func withHeadersUpdatesHeaders() {
        let config = URLSessionHTTPClientConfiguration()
        let headers = ["User-Agent": "MyApp/1.0", "Accept": "application/json"]
        let updated = config.withHeaders(headers)

        #expect(updated.httpAdditionalHeaders == headers)
        #expect(updated.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
    }

    @Test("withHeader returns configuration with added header")
    func withHeaderAddsHeader() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config.withHeader(name: "Authorization", value: "Bearer token123")

        #expect(updated.httpAdditionalHeaders["Authorization"] == "Bearer token123")
        #expect(updated.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
    }

    @Test("withHeader can be chained multiple times")
    func withHeaderCanBeChained() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config
            .withHeader(name: "Authorization", value: "Bearer token")
            .withHeader(name: "User-Agent", value: "MyApp/1.0")
            .withHeader(name: "Accept", value: "application/json")

        #expect(updated.httpAdditionalHeaders.count == 3)
        #expect(updated.httpAdditionalHeaders["Authorization"] == "Bearer token")
        #expect(updated.httpAdditionalHeaders["User-Agent"] == "MyApp/1.0")
        #expect(updated.httpAdditionalHeaders["Accept"] == "application/json")
    }

    @Test("builder methods can be chained together")
    func builderMethodsCanBeChained() {
        let config = URLSessionHTTPClientConfiguration()
        let updated = config
            .withRequestTimeout(45.0)
            .withResourceTimeout(120.0)
            .withCellularAccess(false)
            .withCachePolicy(.returnCacheDataElseLoad)
            .withHeader(name: "User-Agent", value: "MyApp/1.0")

        #expect(updated.timeoutIntervalForRequest == 45.0)
        #expect(updated.timeoutIntervalForResource == 120.0)
        #expect(updated.allowsCellularAccess == false)
        #expect(updated.cachePolicy == .returnCacheDataElseLoad)
        #expect(updated.httpAdditionalHeaders["User-Agent"] == "MyApp/1.0")
    }

    @Test("builder methods do not modify original configuration")
    func builderMethodsDoNotModifyOriginal() {
        let original = URLSessionHTTPClientConfiguration(
            timeoutIntervalForRequest: 30,
            allowsCellularAccess: true
        )

        _ = original
            .withRequestTimeout(60.0)
            .withCellularAccess(false)

        // Original should be unchanged
        #expect(original.timeoutIntervalForRequest == 30)
        #expect(original.allowsCellularAccess == true)
    }
}

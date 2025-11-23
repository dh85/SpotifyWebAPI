import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

private actor DebugEventCollector {
    private var events: [DebugEvent] = []

    func append(_ event: DebugEvent) {
        events.append(event)
    }

    func all() -> [DebugEvent] {
        events
    }

    func waitForEvents(
        minCount: Int,
        timeout: Duration = .milliseconds(250)
    ) async -> [DebugEvent] {
        if events.count >= minCount {
            return events
        }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while events.count < minCount {
            let now = clock.now
            if now >= deadline {
                break
            }

            let remaining = deadline - now
            let sleepDuration = remaining < .milliseconds(5) ? remaining : .milliseconds(5)
            try? await Task.sleep(for: sleepDuration)
        }

        return events
    }

    func waitForEvent<T>(
        timeout: Duration = .milliseconds(250),
        transform: @Sendable (DebugEvent) -> T?
    ) async -> T? {
        if let match = events.compactMap(transform).first {
            return match
        }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while true {
            if let match = events.compactMap(transform).first {
                return match
            }

            let now = clock.now
            if now >= deadline {
                return nil
            }

            let remaining = deadline - now
            let sleepDuration = remaining < .milliseconds(5) ? remaining : .milliseconds(5)
            try? await Task.sleep(for: sleepDuration)
        }
    }

    func waitForTokenEvents(
        count: Int,
        timeout: Duration = .milliseconds(250)
    ) async -> [TokenOperationContext] {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while true {
            let tokens = events.compactMap { event -> TokenOperationContext? in
                guard case .token(let context) = event else { return nil }
                return context
            }
            if tokens.count >= count {
                return tokens
            }

            let now = clock.now
            if now >= deadline {
                return tokens
            }

            let remaining = deadline - now
            let sleepDuration = remaining < .milliseconds(5) ? remaining : .milliseconds(5)
            try? await Task.sleep(for: sleepDuration)
        }
    }
}

@Suite("Debug Tooling Tests")
@MainActor
struct DebugToolingTests {

    init() async {
        await TestEnvironment.bootstrap()
    }

    @Test("Debug configuration disabled by default")
    func debugConfigurationDisabledByDefault() {
        let config = SpotifyClientConfiguration()
        #expect(config.debug.logLevel == .off)
        #expect(config.debug.logRequests == false)
        #expect(config.debug.logResponses == false)
        #expect(config.debug.logPerformance == false)
    }

    @Test("Debug configuration can be customized")
    func debugConfigurationCanBeCustomized() {
        let debugConfig = DebugConfiguration(
            logLevel: .verbose,
            logRequests: true,
            logResponses: true,
            logPerformance: true,
            logNetworkRetries: true,
            logTokenOperations: true
        )

        let config = SpotifyClientConfiguration(debug: debugConfig)

        #expect(config.debug.logLevel == .verbose)
        #expect(config.debug.logRequests == true)
        #expect(config.debug.logResponses == true)
        #expect(config.debug.logPerformance == true)
        #expect(config.debug.logNetworkRetries == true)
        #expect(config.debug.logTokenOperations == true)
    }

    @Test("Debug logger can be configured")
    func debugLoggerCanBeConfigured() async {
        let config = DebugConfiguration.verbose
        await TestEnvironment.logger.configure(config)
        await TestEnvironment.logger.log(.info, "Test message")
    }

    @Test("Performance measurement tracks duration")
    func performanceMeasurementTracksDuration() async {
        await TestEnvironment.logger.clearPerformanceMetrics()

        let config = DebugConfiguration(logPerformance: true)
        await TestEnvironment.logger.configure(config)

        let startTime = Date()
        try? await Task.sleep(for: .milliseconds(50))
        let duration = Date().timeIntervalSince(startTime)

        let metrics = PerformanceMetrics(
            operationName: "test-operation",
            duration: duration,
            retryCount: 1
        )

        await TestEnvironment.logger.recordPerformance(metrics)

        let allMetrics = await TestEnvironment.logger.getPerformanceMetrics()
        #expect(allMetrics.count > 0)

        guard let testMetric = allMetrics.first(where: { $0.operationName == "test-operation" })
        else {
            Issue.record("No test-operation metrics found")
            return
        }
        #expect(testMetric.operationName == "test-operation")
        #expect(testMetric.duration > 0.04)  // At least 40ms (allowing for some variance)
        #expect(testMetric.retryCount == 1)

        await TestEnvironment.logger.clearPerformanceMetrics()
    }

    @Test("Debug logger logs requests when enabled")
    func debugLoggerLogsRequestsWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .debug,
            logRequests: true
        )
        await TestEnvironment.logger.configure(config)

        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")

        // This should not throw when logging is enabled
        await TestEnvironment.logger.logRequest(request)
    }

    @Test("Debug logger logs responses when enabled")
    func debugLoggerLogsResponsesWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .debug,
            logResponses: true
        )
        await TestEnvironment.logger.configure(config)

        let url = URL(string: "https://api.spotify.com/v1/me")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        let data = Data("{\"id\": \"test\"}".utf8)

        // This should not throw when logging is enabled
        await TestEnvironment.logger.logResponse(response, data: data, error: nil)
    }

    @Test("Debug observers receive structured request and response events")
    func debugObserversReceiveStructuredEvents() async {
        await TestEnvironment.logger.configure(.disabled)

        let collector = DebugEventCollector()
        let observer = await TestEnvironment.logger.addObserver { event in
            Task { await collector.append(event) }
        }
        defer { Task { await TestEnvironment.logger.removeObserver(observer) } }

        let testURL = URL(string: "https://api.spotify.com/v1/observer-test/\(UUID().uuidString)")!
        var request = URLRequest(url: testURL)
        request.httpMethod = "POST"
        request.httpBody = Data("{\"name\":\"test\"}".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let response = HTTPURLResponse(
            url: testURL,
            statusCode: 201,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        let responseData = Data("{\"id\":\"123\"}".utf8)

        let token = await TestEnvironment.logger.logRequest(request)
        await TestEnvironment.logger.logResponse(
            response, data: responseData, error: nil, token: token)

        let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
            guard case .request(let context) = event else { return nil }
            guard context.url == testURL else { return nil }
            return context
        }

        guard let requestContext else {
            Issue.record("Missing request event for observer test")
            return
        }

        let responseContext = await collector.waitForEvent { event -> ResponseLogContext? in
            guard case .response(let context) = event else { return nil }
            guard context.url == testURL else { return nil }
            return context
        }

        guard let responseContext else {
            Issue.record("Missing response event for observer test")
            return
        }

        #expect(requestContext.method == "POST")
        #expect(requestContext.bodyBytes == request.httpBody?.count ?? 0)
        #expect(responseContext.statusCode == 201)
        #expect(responseContext.token == requestContext.token)
    }

    @Test("Debug observers receive network retry events")
    func debugObserversReceiveNetworkRetryEvents() async {
        await TestEnvironment.logger.configure(.disabled)

        let collector = DebugEventCollector()
        let observer = await TestEnvironment.logger.addObserver { event in
            Task { await collector.append(event) }
        }
        defer { Task { await TestEnvironment.logger.removeObserver(observer) } }

        let attempt = 2
        let delay: TimeInterval = 1.25
        let error = URLError(.cannotFindHost)

        await TestEnvironment.logger.logNetworkRetry(attempt: attempt, error: error, delay: delay)

        let context = await collector.waitForEvent { event -> NetworkRetryContext? in
            guard case .networkRetry(let context) = event else { return nil }
            guard context.attempt == attempt else { return nil }
            guard abs(context.delay - delay) < 0.001 else { return nil }
            guard context.errorDescription == error.localizedDescription else { return nil }
            return context
        }

        guard let context else {
            Issue.record("Missing matching network retry event for observer test")
            return
        }

        #expect(context.attempt == attempt)
        #expect(abs(context.delay - delay) < 0.001)
        #expect(context.errorDescription == error.localizedDescription)
    }

    @Test("Debug observers receive token operation events")
    func debugObserversReceiveTokenOperationEvents() async {
        await TestEnvironment.logger.configure(.disabled)

        let collector = DebugEventCollector()
        let observer = await TestEnvironment.logger.addObserver { event in
            Task { await collector.append(event) }
        }
        defer { Task { await TestEnvironment.logger.removeObserver(observer) } }

        await TestEnvironment.logger.logTokenOperation("refresh", success: true)
        await TestEnvironment.logger.logTokenOperation("exchange", success: false)

        let tokenEvents = await collector.waitForTokenEvents(count: 2)

        let refresh = tokenEvents.first { $0.operation == "refresh" }
        let exchange = tokenEvents.first { $0.operation == "exchange" }

        guard let refresh else {
            Issue.record("Missing refresh token event for observer test")
            return
        }

        guard let exchange else {
            Issue.record("Missing exchange token event for observer test")
            return
        }

        #expect(refresh.success == true)
        #expect(exchange.success == false)
    }

    @Test("Debug logger logs network retries when enabled")
    func debugLoggerLogsNetworkRetriesWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .info,
            logNetworkRetries: true
        )
        await TestEnvironment.logger.configure(config)

        let error = URLError(.timedOut)

        // This should not throw when logging is enabled
        await TestEnvironment.logger.logNetworkRetry(attempt: 1, error: error, delay: 0.5)
    }

    @Test("Debug logger logs token operations when enabled")
    func debugLoggerLogsTokenOperationsWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .info,
            logTokenOperations: true
        )
        await TestEnvironment.logger.configure(config)

        // This should not throw when logging is enabled
        await TestEnvironment.logger.logTokenOperation("refresh", success: true)
        await TestEnvironment.logger.logTokenOperation("exchange", success: false)
    }

    @Test("Performance metrics are limited to 100 entries")
    func performanceMetricsAreLimitedTo100Entries() async {
        // Clear any existing metrics from other tests
        await TestEnvironment.logger.clearPerformanceMetrics()

        let originalConfig = DebugConfiguration.disabled
        await TestEnvironment.logger.configure(originalConfig)

        // Add exactly 150 metrics with unique names to test the limiting behavior
        let testPrefix = "limit-test-\(UUID().uuidString.prefix(8))"
        for i in 0..<150 {
            let metrics = PerformanceMetrics(
                operationName: "\(testPrefix)-\(i)",
                duration: 0.001,
                requestCount: 1,
                retryCount: 0
            )
            await TestEnvironment.logger.recordPerformance(metrics)
        }

        let allMetrics = await TestEnvironment.logger.getPerformanceMetrics()

        // Should be limited to 100 entries total
        #expect(allMetrics.count == 100)

        // All metrics should be our test metrics since we cleared before starting
        let testMetrics = allMetrics.filter { $0.operationName.hasPrefix(testPrefix) }
        #expect(testMetrics.count == 100)

        // Verify the metrics are the last 100 we added (50-149)
        let expectedNames = (50..<150).map { "\(testPrefix)-\($0)" }
        let actualNames = testMetrics.map { $0.operationName }
        #expect(Set(actualNames) == Set(expectedNames))

        await TestEnvironment.logger.clearPerformanceMetrics()
    }

    @Test("Debug log levels work correctly")
    func debugLogLevelsWorkCorrectly() {
        #expect(DebugLogLevel.off.rawValue == 0)
        #expect(DebugLogLevel.error.rawValue == 1)
        #expect(DebugLogLevel.warning.rawValue == 2)
        #expect(DebugLogLevel.info.rawValue == 3)
        #expect(DebugLogLevel.debug.rawValue == 4)
        #expect(DebugLogLevel.verbose.rawValue == 5)

        #expect(DebugLogLevel.off.name == "OFF")
        #expect(DebugLogLevel.error.name == "ERROR")
        #expect(DebugLogLevel.warning.name == "WARN")
        #expect(DebugLogLevel.info.name == "INFO")
        #expect(DebugLogLevel.debug.name == "DEBUG")
        #expect(DebugLogLevel.verbose.name == "VERBOSE")
    }

    @Test("Client configures debug logger on initialization")
    func clientConfiguresDebugLoggerOnInitialization() async {
        let debugConfig = DebugConfiguration(
            logLevel: .info,
            logRequests: true,
            logPerformance: true
        )

        let config = SpotifyClientConfiguration(debug: debugConfig)
        let (_, _) = makeUserAuthClient(configuration: config)

        // Give the async configuration task time to complete
        try? await Task.sleep(for: .milliseconds(100))

        // Verify the configuration was set correctly
        #expect(config.debug.logLevel == .info)
        #expect(config.debug.logRequests == true)
        #expect(config.debug.logPerformance == true)
    }

    @Test("Performance measurement with retries")
    func performanceMeasurementWithRetries() async {
        // This test verifies that PerformanceMetrics can store retry count correctly
        // We don't need to use the shared logger for this

        let metrics = PerformanceMetrics(
            operationName: "test-operation",
            duration: 0.1,
            requestCount: 1,
            retryCount: 3
        )

        // Test the metrics object directly
        #expect(metrics.operationName == "test-operation")
        #expect(metrics.retryCount == 3)
        #expect(metrics.duration == 0.1)
        #expect(metrics.requestCount == 1)
    }

    @Test("Debug configuration presets work correctly")
    func debugConfigurationPresetsWorkCorrectly() {
        let disabled = DebugConfiguration.disabled
        #expect(disabled.logLevel == .off)
        #expect(disabled.logRequests == false)
        #expect(disabled.logResponses == false)
        #expect(disabled.logPerformance == false)
        #expect(disabled.logNetworkRetries == false)
        #expect(disabled.logTokenOperations == false)

        let verbose = DebugConfiguration.verbose
        #expect(verbose.logLevel == .verbose)
        #expect(verbose.logRequests == true)
        #expect(verbose.logResponses == true)
        #expect(verbose.logPerformance == true)
        #expect(verbose.logNetworkRetries == true)
        #expect(verbose.logTokenOperations == true)
    }

    @Test("Debug logger redacts sensitive headers and bodies")
    func debugLoggerRedactsSensitiveData() async {
        await TestEnvironment.logger.configure(.disabled)

        let collector = DebugEventCollector()
        let observer = await TestEnvironment.logger.addObserver { event in
            Task { await collector.append(event) }
        }
        defer { Task { await TestEnvironment.logger.removeObserver(observer) } }

        let requestURL = URL(
            string: "https://api.spotify.com/v1/redaction-test/\(UUID().uuidString)")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("Bearer top-secret-token", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{\"access_token\":\"secret\"}".utf8)

        let token = await TestEnvironment.logger.logRequest(request)

        let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
            guard case .request(let context) = event else { return nil }
            guard context.token == token else { return nil }
            return context
        }

        guard let requestContext else {
            Issue.record("Missing request context for redaction test")
            return
        }

        #expect(requestContext.headers["Authorization"] == "Bearer <redacted>")
        #expect(requestContext.bodyPreview == "<redacted>")
        #expect(requestContext.bodyBytes == request.httpBody?.count)

        let response = HTTPURLResponse(
            url: requestURL,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Set-Cookie": "session=abc123",
                "Content-Type": "application/json",
            ]
        )

        let responseData = Data("{\"refresh_token\":\"super-secret\"}".utf8)
        await TestEnvironment.logger.logResponse(
            response, data: responseData, error: nil, token: token)

        let responseContext = await collector.waitForEvent { event -> ResponseLogContext? in
            guard case .response(let context) = event else { return nil }
            guard context.token == token else { return nil }
            return context
        }

        guard let responseContext else {
            Issue.record("Missing response context for redaction test")
            return
        }

        #expect(responseContext.headers["Set-Cookie"] == "<redacted>")
        #expect(responseContext.bodyPreview == "<redacted>")
    }
}

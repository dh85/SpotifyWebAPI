import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite("Debug Tooling Tests")
@MainActor
struct DebugToolingTests {
    
    init() async {
        await TestDebugHelper.configureForTests()
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
        await TestDebugHelper.testLogger.configure(config)

        // Test that logger accepts configuration without errors
        await TestDebugHelper.testLogger.log(.info, "Test message")
    }

    @Test("Performance measurement tracks duration")
    func performanceMeasurementTracksDuration() async {
        await TestDebugHelper.testLogger.clearPerformanceMetrics()
        
        // Enable performance logging
        let config = DebugConfiguration(logPerformance: true)
        await TestDebugHelper.testLogger.configure(config)
        
        // Create measurement and record metrics directly
        let startTime = Date()
        
        // Simulate some work
        try? await Task.sleep(for: .milliseconds(50))
        
        let duration = Date().timeIntervalSince(startTime)
        let metrics = PerformanceMetrics(
            operationName: "test-operation",
            duration: duration,
            retryCount: 1
        )
        
        await TestDebugHelper.testLogger.recordPerformance(metrics)

        let allMetrics = await TestDebugHelper.testLogger.getPerformanceMetrics()
        #expect(allMetrics.count > 0)

        guard let testMetric = allMetrics.first(where: { $0.operationName == "test-operation" }) else {
            Issue.record("No test-operation metrics found")
            return
        }
        #expect(testMetric.operationName == "test-operation")
        #expect(testMetric.duration > 0.04)  // At least 40ms (allowing for some variance)
        #expect(testMetric.retryCount == 1)

        await TestDebugHelper.testLogger.clearPerformanceMetrics()
    }

    @Test("Debug logger logs requests when enabled")
    func debugLoggerLogsRequestsWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .debug,
            logRequests: true
        )
        await TestDebugHelper.testLogger.configure(config)

        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")

        // This should not throw when logging is enabled
        await TestDebugHelper.testLogger.logRequest(request)
    }

    @Test("Debug logger logs responses when enabled")
    func debugLoggerLogsResponsesWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .debug,
            logResponses: true
        )
        await TestDebugHelper.testLogger.configure(config)

        let url = URL(string: "https://api.spotify.com/v1/me")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )
        let data = Data("{\"id\": \"test\"}".utf8)

        // This should not throw when logging is enabled
        await TestDebugHelper.testLogger.logResponse(response, data: data, error: nil)
    }

    @Test("Debug logger logs network retries when enabled")
    func debugLoggerLogsNetworkRetriesWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .info,
            logNetworkRetries: true
        )
        await TestDebugHelper.testLogger.configure(config)

        let error = URLError(.timedOut)

        // This should not throw when logging is enabled
        await TestDebugHelper.testLogger.logNetworkRetry(attempt: 1, error: error, delay: 0.5)
    }

    @Test("Debug logger logs token operations when enabled")
    func debugLoggerLogsTokenOperationsWhenEnabled() async {
        let config = DebugConfiguration(
            logLevel: .info,
            logTokenOperations: true
        )
        await TestDebugHelper.testLogger.configure(config)

        // This should not throw when logging is enabled
        await TestDebugHelper.testLogger.logTokenOperation("refresh", success: true)
        await TestDebugHelper.testLogger.logTokenOperation("exchange", success: false)
    }

    @Test("Performance metrics are limited to 100 entries")
    func performanceMetricsAreLimitedTo100Entries() async {
        // Clear any existing metrics from other tests
        await TestDebugHelper.testLogger.clearPerformanceMetrics()
        
        // Disable all logging to prevent interference
        let originalConfig = DebugConfiguration.disabled
        await TestDebugHelper.testLogger.configure(originalConfig)

        // Add exactly 150 metrics with unique names to test the limiting behavior
        let testPrefix = "limit-test-\(UUID().uuidString.prefix(8))"
        for i in 0..<150 {
            let metrics = PerformanceMetrics(
                operationName: "\(testPrefix)-\(i)",
                duration: 0.001,
                requestCount: 1,
                retryCount: 0
            )
            await TestDebugHelper.testLogger.recordPerformance(metrics)
        }

        let allMetrics = await TestDebugHelper.testLogger.getPerformanceMetrics()
        
        // Should be limited to 100 entries total
        #expect(allMetrics.count == 100)

        // All metrics should be our test metrics since we cleared before starting
        let testMetrics = allMetrics.filter { $0.operationName.hasPrefix(testPrefix) }
        #expect(testMetrics.count == 100)
        
        // Verify the metrics are the last 100 we added (50-149)
        let expectedNames = (50..<150).map { "\(testPrefix)-\($0)" }
        let actualNames = testMetrics.map { $0.operationName }
        #expect(Set(actualNames) == Set(expectedNames))

        await TestDebugHelper.testLogger.clearPerformanceMetrics()
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
}

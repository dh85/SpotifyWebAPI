import Foundation
import Testing

@testable import SpotifyKit

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
        guard case .tokenOperation(let context) = event else { return nil }
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
    let logger = DebugLogger()
    let config = DebugConfiguration.verbose
    await logger.configure(config)
    await logger.log(.info, "Test message")
  }

  @Test("Performance measurement tracks duration")
  func performanceMeasurementTracksDuration() async {
    let logger = DebugLogger()
    // await logger.clearPerformanceMetrics() // New instance is already clear

    let config = DebugConfiguration(logPerformance: true)
    await logger.configure(config)

    let startTime = Date()
    try? await Task.sleep(for: .milliseconds(50))
    let duration = Date().timeIntervalSince(startTime)

    let metrics = PerformanceMetrics(
      operationName: "test-operation",
      duration: duration,
      retryCount: 1
    )

    await logger.recordPerformance(metrics)

    let allMetrics = await logger.getPerformanceMetrics()
    #expect(allMetrics.count > 0)

    guard let testMetric = allMetrics.first(where: { $0.operationName == "test-operation" })
    else {
      Issue.record("No test-operation metrics found")
      return
    }
    #expect(testMetric.operationName == "test-operation")
    #expect(testMetric.duration > 0.04)  // At least 40ms (allowing for some variance)
    #expect(testMetric.retryCount == 1)

    // await logger.clearPerformanceMetrics()
  }

  @Test("Debug logger logs requests when enabled")
  func debugLoggerLogsRequestsWhenEnabled() async {
    let logger = DebugLogger()
    let config = DebugConfiguration(
      logLevel: .debug,
      logRequests: true
    )
    await logger.configure(config)

    let url = URL(string: "https://api.spotify.com/v1/me")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")

    // This should not throw when logging is enabled
    await logger.logRequest(request)
  }

  @Test("Debug logger logs responses when enabled")
  func debugLoggerLogsResponsesWhenEnabled() async {
    let logger = DebugLogger()
    let config = DebugConfiguration(
      logLevel: .debug,
      logResponses: true
    )
    await logger.configure(config)

    let url = URL(string: "https://api.spotify.com/v1/me")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )
    let data = Data("{\"id\": \"test\"}".utf8)

    // This should not throw when logging is enabled
    await logger.logResponse(response, data: data, error: nil)
  }

  @Test("Debug observers receive structured request and response events")
  func debugObserversReceiveStructuredEvents() async {
    let logger = DebugLogger()
    await logger.configure(.disabled)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

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

    let token = await logger.logRequest(request)
    await logger.logResponse(
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
    let logger = DebugLogger()
    await logger.configure(.disabled)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    let attempt = 2
    let delay: TimeInterval = 1.25
    let error = URLError(.cannotFindHost)

    await logger.logNetworkRetry(attempt: attempt, error: error, delay: delay)

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
    let logger = DebugLogger()
    await logger.configure(.disabled)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    await logger.logTokenOperation("refresh", success: true)
    await logger.logTokenOperation("exchange", success: false)

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

  @Test("SpotifyClientObserver protocol receives events")
  func spotifyClientObserverProtocolReceivesEvents() async {
    let logger = DebugLogger()
    await logger.configure(.disabled)

    let collector = DebugEventCollector()
    struct CollectingObserver: SpotifyClientObserver {
      let collector: DebugEventCollector
      func receive(_ event: SpotifyClientEvent) {
        Task { await collector.append(event) }
      }
    }

    let observerToken = await logger.addObserver(
      CollectingObserver(collector: collector)
    )
    defer { Task { await logger.removeObserver(observerToken) } }

    await logger.logTokenOperation("observer-protocol", success: true)

    let events = await collector.waitForTokenEvents(count: 1)
    #expect(events.contains { $0.operation == "observer-protocol" })
  }

  @Test("Debug logger logs network retries when enabled")
  func debugLoggerLogsNetworkRetriesWhenEnabled() async {
    let logger = DebugLogger()
    let config = DebugConfiguration(
      logLevel: .info,
      logNetworkRetries: true
    )
    await logger.configure(config)

    let error = URLError(.timedOut)

    // This should not throw when logging is enabled
    await logger.logNetworkRetry(attempt: 1, error: error, delay: 0.5)
  }

  @Test("Debug logger logs token operations when enabled")
  func debugLoggerLogsTokenOperationsWhenEnabled() async {
    let logger = DebugLogger()
    let config = DebugConfiguration(
      logLevel: .info,
      logTokenOperations: true
    )
    await logger.configure(config)

    // This should not throw when logging is enabled
    await logger.logTokenOperation("refresh", success: true)
    await logger.logTokenOperation("exchange", success: false)
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
    let (client, _) = makeUserAuthClient(configuration: config)

    // Give the async configuration task time to complete
    try? await Task.sleep(for: .milliseconds(100))

    // Verify the configuration was set correctly on the client's logger
    let snapshot = await client.logger.configurationSnapshotForTests()
    #expect(snapshot.logLevel == .info)
    #expect(snapshot.logRequests == true)
    #expect(snapshot.logPerformance == true)
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

  @Test("Debug logger sanitizes release configurations")
  func debugLoggerSanitizesReleaseConfigurations() async {
    #if DEBUG
      let logger = DebugLogger()
      await logger.resetWarningFlagsForTests()
      await logger.overrideIsDebugBuildForTests(false)

      let unsafeConfig = DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        logNetworkRetries: true,
        logTokenOperations: true
      )

      await logger.configure(unsafeConfig)
      let sanitized = await logger.configurationSnapshotForTests()

      #expect(sanitized.logLevel == .info)
      #expect(sanitized.logRequests == false)
      #expect(sanitized.logResponses == false)
      #expect(sanitized.allowSensitivePayloads == false)
      #expect(await logger.didLogProductionRestrictionWarningForTests())

      await logger.overrideIsDebugBuildForTests(nil)
    #else
      Issue.record("Debug build required for sanitization test")
    #endif
  }

  @Test("Debug logger redacts sensitive headers and bodies")
  func debugLoggerRedactsSensitiveData() async {
    let logger = DebugLogger()
    await logger.configure(.disabled)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    let requestURL = URL(
      string: "https://api.spotify.com/v1/redaction-test/\(UUID().uuidString)")!
    var request = URLRequest(url: requestURL)
    request.httpMethod = "POST"
    request.setValue("Bearer top-secret-token", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data("{\"access_token\":\"secret\"}".utf8)

    let token = await logger.logRequest(request)

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
    #expect(requestContext.bodyPreview == DebugLogger.redactedBodyPlaceholder)
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
    await logger.logResponse(
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
    #expect(responseContext.bodyPreview == DebugLogger.redactedBodyPlaceholder)
  }

  @Test("Debug logger redacts bodies even when verbose logging is enabled")
  func debugLoggerRedactsBodiesWhenSensitiveLoggingDisabled() async {
    let logger = DebugLogger()
    await logger.configure(
      DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        allowSensitivePayloads: false
      )
    )

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    let url = URL(string: "https://api.spotify.com/v1/tokens")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data("{\"access_token\":\"secret\"}".utf8)

    let token = await logger.logRequest(request)
    let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
      guard case .request(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let requestContext else {
      Issue.record("Missing request context for sensitive payload test")
      return
    }

    #expect(requestContext.bodyPreview == DebugLogger.redactedBodyPlaceholder)

    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )
    let responseData = Data("{\"refresh_token\":\"secret\"}".utf8)
    await logger.logResponse(
      response, data: responseData, error: nil, token: token)

    let responseContext = await collector.waitForEvent { event -> ResponseLogContext? in
      guard case .response(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let responseContext else {
      Issue.record("Missing response context for sensitive payload test")
      return
    }

    #expect(responseContext.bodyPreview == DebugLogger.redactedBodyPlaceholder)
  }

  @Test("Debug logger never logs access tokens in plain text")
  func debugLoggerNeverLogsAccessTokensInPlainText() async {
    let logger = DebugLogger()
    await logger.configure(
      DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        logPerformance: true,
        logNetworkRetries: true,
        logTokenOperations: true,
        allowSensitivePayloads: true
      )
    )

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    // Simulate a request with Authorization header
    let requestURL = URL(string: "https://api.spotify.com/v1/me/player")!
    var request = URLRequest(url: requestURL)
    request.setValue(
      "Bearer my-super-secret-access-token-12345", forHTTPHeaderField: "Authorization")

    let token = await logger.logRequest(request)

    let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
      guard case .request(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let requestContext else {
      Issue.record("Missing request context for access token test")
      return
    }

    // Verify the Authorization header is redacted
    let authHeader = requestContext.headers["Authorization"]
    #expect(authHeader == "Bearer <redacted>", "Authorization header must be redacted")
    #expect(
      !authHeader!.contains("my-super-secret-access-token-12345"),
      "Plain text access token must never appear in logs")
  }

  @Test("Debug logger never logs refresh tokens in response bodies")
  func debugLoggerNeverLogsRefreshTokensInResponseBodies() async {
    let logger = DebugLogger()
    await logger.configure(.verbose)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    // Simulate OAuth token response
    let responseURL = URL(string: "https://accounts.spotify.com/api/token")!
    let response = HTTPURLResponse(
      url: responseURL,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )

    let tokenResponse = """
      {
          "access_token": "NgCXRK...MzYjw",
          "token_type": "Bearer",
          "expires_in": 3600,
          "refresh_token": "NgAagA...Um_SHo",
          "scope": "user-read-private user-read-email"
      }
      """
    let responseData = Data(tokenResponse.utf8)

    let token = await logger.logRequest(URLRequest(url: responseURL))
    await logger.logResponse(
      response, data: responseData, error: nil, token: token)

    let responseContext = await collector.waitForEvent { event -> ResponseLogContext? in
      guard case .response(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let responseContext else {
      Issue.record("Missing response context for refresh token test")
      return
    }

    // Verify response body containing tokens is redacted
    let expectedPlaceholder = DebugLogger.redactedBodyPlaceholder
    #expect(
      responseContext.bodyPreview == expectedPlaceholder,
      "Token response body must be redacted")
    #expect(
      !responseContext.bodyPreview!.contains("NgCXRK"), "Access token must not appear in logs"
    )
    #expect(
      !responseContext.bodyPreview!.contains("NgAagA"),
      "Refresh token must not appear in logs")
  }

  @Test("Debug logger redacts all sensitive header types")
  func debugLoggerRedactsAllSensitiveHeaders() async {
    let logger = DebugLogger()
    await logger.configure(.verbose)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    // Test all sensitive header types
    let sensitiveHeaders: [String: String] = [
      "Authorization": "Bearer token123",
      "Proxy-Authorization": "Basic abc123",
      "Cookie": "session=xyz789",
      "Set-Cookie": "auth=def456; HttpOnly",
      "X-Spotify-Authorization": "Custom token999",
      "X-API-Key": "apikey888",
    ]

    let requestURL = URL(string: "https://api.spotify.com/v1/test")!
    var request = URLRequest(url: requestURL)
    for (header, value) in sensitiveHeaders {
      request.setValue(value, forHTTPHeaderField: header)
    }

    let token = await logger.logRequest(request)

    let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
      guard case .request(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let requestContext else {
      Issue.record("Missing request context for sensitive headers test")
      return
    }

    // Verify all sensitive headers are redacted
    for (headerName, originalValue) in sensitiveHeaders {
      // HTTP headers are case-insensitive, find the actual logged key
      let loggedKey = requestContext.headers.keys.first {
        $0.lowercased() == headerName.lowercased()
      }
      let loggedValue = loggedKey.flatMap { requestContext.headers[$0] }
      #expect(loggedValue != originalValue, "\(headerName) must be redacted")
      #expect(
        loggedValue?.contains("<redacted>") == true
          || loggedValue?.contains("Bearer <redacted>") == true
          || loggedValue?.contains("Basic <redacted>") == true,
        "\(headerName) must show <redacted> placeholder")
    }
  }

  @Test("Debug logger preserves URLs for debugging context")
  func debugLoggerPreservesURLsForDebugging() async {
    let logger = DebugLogger()
    await logger.configure(.verbose)

    let collector = DebugEventCollector()
    let observer = await logger.addObserver { event in
      Task { await collector.append(event) }
    }
    defer { Task { await logger.removeObserver(observer) } }

    // URL with token in query parameter (bad practice, but logger preserves URL for debugging)
    let requestURL = URL(string: "https://api.spotify.com/v1/tracks?access_token=secret123")!
    let request = URLRequest(url: requestURL)

    let token = await logger.logRequest(request)

    let requestContext = await collector.waitForEvent { event -> RequestLogContext? in
      guard case .request(let context) = event else { return nil }
      guard context.token == token else { return nil }
      return context
    }

    guard let requestContext else {
      Issue.record("Missing request context for URL preservation test")
      return
    }

    // URLs are preserved for debugging context (developers need full URL to reproduce issues)
    // Security best practice: never put tokens in URLs in the first place
    let loggedURL = requestContext.url?.absoluteString ?? ""
    #expect(
      loggedURL == "https://api.spotify.com/v1/tracks?access_token=secret123",
      "URLs are preserved for debugging (tokens should never be in URLs)")
  }

  @Test("Debug logger is disabled by default in production")
  func debugLoggerDisabledByDefaultInProduction() async {
    #if DEBUG
      let logger = DebugLogger()
      await logger.resetWarningFlagsForTests()
      await logger.overrideIsDebugBuildForTests(false)

      let collector = DebugEventCollector()
      let observer = await logger.addObserver { event in
        Task { await collector.append(event) }
      }
      defer { Task { await logger.removeObserver(observer) } }

      // Try to enable verbose logging with sensitive features
      let productionConfig = DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        logTokenOperations: true
      )

      await logger.configure(productionConfig)

      // Make a request
      let requestURL = URL(string: "https://api.spotify.com/v1/me")!
      var request = URLRequest(url: requestURL)
      request.setValue("Bearer production-token", forHTTPHeaderField: "Authorization")

      let _ = await logger.logRequest(request)

      // Wait briefly for any events
      let events = await collector.waitForEvents(minCount: 1, timeout: .milliseconds(100))

      // Observers still receive instrumentation even in production builds so they can
      // surface telemetry without enabling verbose logging. However, the configuration
      // must be sanitized to ensure nothing is actually written to logs.
      #expect(events.contains { if case .request = $0 { true } else { false } })

      let config = await logger.configurationSnapshotForTests()
      #expect(
        config.logRequests == false, "Request logging must be disabled in production builds"
      )
      #expect(
        config.logResponses == false,
        "Response logging must be disabled in production builds")
      #expect(
        config.logLevel.rawValue <= DebugLogLevel.info.rawValue,
        "Verbose log levels must be clamped in production builds")

      let didWarn = await logger.didLogProductionRestrictionWarningForTests()
      #expect(didWarn == true, "Production restriction warning must be emitted")

      await logger.overrideIsDebugBuildForTests(nil)
    #else
      // In actual production builds, just verify the configuration sanitization works
      let logger = DebugLogger()
      let productionConfig = DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true
      )

      await logger.configure(productionConfig)
      let actual = await logger.configurationSnapshotForTests()

      #expect(actual.logRequests == false, "Sensitive logging must be disabled in production")
      #expect(
        actual.logResponses == false, "Sensitive logging must be disabled in production")
    #endif
  }
}

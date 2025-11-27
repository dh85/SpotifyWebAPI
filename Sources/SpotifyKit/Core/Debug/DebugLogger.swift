import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

#if canImport(os)
    import os
#endif

/// Debug logging levels for SpotifyKit
public enum DebugLogLevel: Int, CaseIterable, Sendable {
    case off = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case verbose = 5

    public var name: String {
        switch self {
        case .off: return "OFF"
        case .error: return "ERROR"
        case .warning: return "WARN"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .verbose: return "VERBOSE"
        }
    }
}

/// Debug configuration for SpotifyKit
public struct DebugConfiguration: Sendable {
    public let logLevel: DebugLogLevel
    public let logRequests: Bool
    public let logResponses: Bool
    public let logPerformance: Bool
    public let logNetworkRetries: Bool
    public let logTokenOperations: Bool
    public let allowSensitivePayloads: Bool

    public init(
        logLevel: DebugLogLevel = .off,
        logRequests: Bool = false,
        logResponses: Bool = false,
        logPerformance: Bool = false,
        logNetworkRetries: Bool = false,
        logTokenOperations: Bool = false,
        allowSensitivePayloads: Bool = false
    ) {
        self.logLevel = logLevel
        self.logRequests = logRequests
        self.logResponses = logResponses
        self.logPerformance = logPerformance
        self.logNetworkRetries = logNetworkRetries
        self.logTokenOperations = logTokenOperations
        self.allowSensitivePayloads = allowSensitivePayloads
    }

    public static let disabled = DebugConfiguration()

    public static let verbose = DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        logPerformance: true,
        logNetworkRetries: true,
        logTokenOperations: true,
        allowSensitivePayloads: true
    )
}

/// Performance metrics for API operations
public struct PerformanceMetrics: Sendable {
    public let operationName: String
    public let duration: TimeInterval
    public let requestCount: Int
    public let retryCount: Int
    public let timestamp: Date

    public init(
        operationName: String,
        duration: TimeInterval,
        requestCount: Int = 1,
        retryCount: Int = 0,
        timestamp: Date = Date()
    ) {
        self.operationName = operationName
        self.duration = duration
        self.requestCount = requestCount
        self.retryCount = retryCount
        self.timestamp = timestamp
    }
}

/// Token that links request and response events together.
public struct RequestLogToken: Hashable, Sendable {
    public let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

/// Structured context for request logging hooks.
public struct RequestLogContext: Sendable {
    public let token: RequestLogToken
    public let method: String
    public let url: URL?
    public let headers: [String: String]
    public let bodyBytes: Int
    public let bodyPreview: String?
    public let timestamp: Date

    public init(
        token: RequestLogToken,
        method: String,
        url: URL?,
        headers: [String: String],
        bodyBytes: Int,
        bodyPreview: String?,
        timestamp: Date = Date()
    ) {
        self.token = token
        self.method = method
        self.url = url
        self.headers = headers
        self.bodyBytes = bodyBytes
        self.bodyPreview = bodyPreview
        self.timestamp = timestamp
    }
}

/// Structured context for response logging hooks.
public struct ResponseLogContext: Sendable {
    public let token: RequestLogToken?
    public let statusCode: Int?
    public let url: URL?
    public let headers: [String: String]
    public let dataBytes: Int
    public let bodyPreview: String?
    public let errorDescription: String?
    public let timestamp: Date

    public init(
        token: RequestLogToken?,
        statusCode: Int?,
        url: URL?,
        headers: [String: String],
        dataBytes: Int,
        bodyPreview: String?,
        errorDescription: String?,
        timestamp: Date = Date()
    ) {
        self.token = token
        self.statusCode = statusCode
        self.url = url
        self.headers = headers
        self.dataBytes = dataBytes
        self.bodyPreview = bodyPreview
        self.errorDescription = errorDescription
        self.timestamp = timestamp
    }
}

/// Structured context for network retry events.
public struct NetworkRetryContext: Sendable {
    public let attempt: Int
    public let delay: TimeInterval
    public let errorDescription: String
    public let timestamp: Date

    public init(
        attempt: Int,
        delay: TimeInterval,
        errorDescription: String,
        timestamp: Date = Date()
    ) {
        self.attempt = attempt
        self.delay = delay
        self.errorDescription = errorDescription
        self.timestamp = timestamp
    }
}

/// Structured context for token operation events.
public struct TokenOperationContext: Sendable {
    public let operation: String
    public let success: Bool
    public let timestamp: Date

    public init(operation: String, success: Bool, timestamp: Date = Date()) {
        self.operation = operation
        self.success = success
        self.timestamp = timestamp
    }
}

/// Lightweight payload emitted when token refresh fails.
public struct TokenRefreshFailureContext: Sendable {
    public let errorDescription: String

    public init(errorDescription: String) {
        self.errorDescription = errorDescription
    }

    public init(error: Error) {
        self.errorDescription = String(describing: error)
    }
}

/// Event payload emitted by the debug logger.
public enum SpotifyClientEvent: Sendable {
    case request(RequestLogContext)
    case response(ResponseLogContext)
    case networkRetry(NetworkRetryContext)
    case tokenOperation(TokenOperationContext)
    case performance(PerformanceMetrics)
    case rateLimit(RateLimitInfo)
    case tokenRefreshWillStart(TokenRefreshInfo)
    case tokenRefreshDidSucceed(SpotifyTokens)
    case tokenRefreshDidFail(TokenRefreshFailureContext)
}

/// Backward-compatible alias for previously named DebugEvent.
public typealias DebugEvent = SpotifyClientEvent

/// Handler closure for receiving instrumentation events.
public typealias SpotifyClientEventHandler = @Sendable (SpotifyClientEvent) -> Void

/// Backward-compatible alias used by DebugLogger APIs.
public typealias DebugEventHandler = SpotifyClientEventHandler

/// Observer protocol that receives structured client events.
public protocol SpotifyClientObserver: Sendable {
    func receive(_ event: SpotifyClientEvent)
}

/// Token returned when registering a debug event observer.
public struct DebugLogObserver: Hashable, Sendable {
    fileprivate let id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

/// Debug logger for SpotifyKit
@globalActor
public actor DebugLogger {
    public static let shared = DebugLogger()

    #if DEBUG
        private var debugBuildOverride: Bool?
    #endif

    private var isDebugBuild: Bool {
        #if DEBUG
            if let override = debugBuildOverride {
                return override
            }
            return true
        #else
            return false
        #endif
    }

    private var configuration: DebugConfiguration = .disabled
    private var performanceMetrics: [PerformanceMetrics] = []
    private var observers: [UUID: DebugEventHandler] = [:]
    private var hasLoggedExposureWarning = false
    private var hasLoggedObserverWarning = false
    private var hasLoggedProductionRestriction = false

    #if canImport(os)
        private let osLog = Logger(subsystem: "com.spotifykit", category: "debug")
    #endif

    public init() {}

    #if DEBUG
        internal func overrideIsDebugBuildForTests(_ value: Bool?) {
            debugBuildOverride = value
        }

        internal func configurationSnapshotForTests() -> DebugConfiguration {
            configuration
        }

        internal func resetWarningFlagsForTests() {
            hasLoggedExposureWarning = false
            hasLoggedObserverWarning = false
            hasLoggedProductionRestriction = false
        }

        internal func didLogProductionRestrictionWarningForTests() -> Bool {
            hasLoggedProductionRestriction
        }
    #endif

    public func configure(_ config: DebugConfiguration) {
        let sanitized = enforceProductionSafety(for: config)
        self.configuration = sanitized
        if sanitized.logRequests || sanitized.logResponses
            || sanitized.logLevel == .verbose
        {
            emitExposureWarning("Request/response logging or verbose level enabled")
        }

        if sanitized.allowSensitivePayloads {
            emitExposureWarning("Sensitive payload logging enabled")
        }
    }

    /// Registers a handler that receives structured debug events.
    @discardableResult
    public func addObserver(_ handler: @escaping DebugEventHandler) -> DebugLogObserver {
        let observer = DebugLogObserver()
        observers[observer.id] = handler
        emitObserverWarningIfNeeded()
        return observer
    }

    /// Registers a typed observer that conforms to ``SpotifyClientObserver``.
    @discardableResult
    public func addObserver(_ observer: SpotifyClientObserver) -> DebugLogObserver {
        addObserver { event in
            observer.receive(event)
        }
    }

    /// Removes a previously registered handler.
    public func removeObserver(_ observer: DebugLogObserver) {
        observers.removeValue(forKey: observer.id)
    }

    /// Emits an instrumentation event to all observers.
    public func emit(_ event: SpotifyClientEvent) {
        notifyObservers(event)
    }

    public func log(
        _ level: DebugLogLevel, _ message: String, file: String = #file,
        function: String = #function, line: Int = #line
    ) {
        guard level.rawValue <= configuration.logLevel.rawValue else { return }

        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.name)] \(fileName):\(line) \(function) - \(message)"

        #if canImport(os)
            switch level {
            case .off:
                break
            case .error:
                osLog.error("\(logMessage)")
            case .warning:
                osLog.warning("\(logMessage)")
            case .info:
                osLog.info("\(logMessage)")
            case .debug, .verbose:
                osLog.debug("\(logMessage)")
            }
        #else
            print(logMessage)
        #endif
    }

    @discardableResult
    public func logRequest(_ request: URLRequest) -> RequestLogToken? {
        let shouldEmit = configuration.logRequests || !observers.isEmpty
        guard shouldEmit else { return nil }

        let token = RequestLogToken()
        let context = makeRequestContext(token: token, request: request)

        if configuration.logRequests {
            var message = "HTTP \(context.method) \(context.url?.absoluteString ?? "unknown")"

            if !context.headers.isEmpty {
                let headerString = context.headers.map { "\($0.key): \($0.value)" }.joined(
                    separator: ", ")
                message += "\nHeaders: \(headerString)"
            }

            if let preview = context.bodyPreview {
                message += "\nBody: \(preview)"
            } else if context.bodyBytes > 0 {
                message += "\nBody: \(context.bodyBytes) bytes"
            }

            log(.debug, "Request: \(message)")
        }

        notifyObservers(.request(context))
        return token
    }

    public func logResponse(
        _ response: URLResponse?,
        data: Data?,
        error: Error?,
        token: RequestLogToken? = nil
    ) {
        let shouldEmit = configuration.logResponses || !observers.isEmpty
        guard shouldEmit else { return }

        let context = makeResponseContext(
            token: token, response: response, data: data, error: error)

        if configuration.logResponses {
            var message = ""

            if let statusCode = context.statusCode {
                message += "HTTP \(statusCode)"
                if let url = context.url {
                    message += " \(url.absoluteString)"
                }
            }

            message += "\nData: \(context.dataBytes) bytes"
            if let preview = context.bodyPreview {
                message += " - \(preview)"
            }

            if let errorDescription = context.errorDescription {
                message += "\nError: \(errorDescription)"
            }

            log(.debug, "Response: \(message)")
        }

        notifyObservers(.response(context))
    }

    public func logNetworkRetry(attempt: Int, error: Error, delay: TimeInterval) {
        let shouldEmit = configuration.logNetworkRetries || !observers.isEmpty
        guard shouldEmit else { return }

        let context = NetworkRetryContext(
            attempt: attempt,
            delay: delay,
            errorDescription: error.localizedDescription
        )

        if configuration.logNetworkRetries {
            log(
                .info,
                "Network retry attempt \(attempt) after \(String(format: "%.2f", delay))s - \(context.errorDescription)"
            )
        }

        notifyObservers(.networkRetry(context))
    }

    public func logTokenOperation(_ operation: String, success: Bool) {
        let shouldEmit = configuration.logTokenOperations || !observers.isEmpty
        guard shouldEmit else { return }

        let context = TokenOperationContext(operation: operation, success: success)

        if configuration.logTokenOperations {
            let status = success ? "SUCCESS" : "FAILED"
            log(.info, "Token operation: \(operation) - \(status)")
        }

        notifyObservers(.tokenOperation(context))
    }

    public func recordPerformance(_ metrics: PerformanceMetrics) {
        performanceMetrics.append(metrics)

        // Keep only last 100 metrics
        if performanceMetrics.count > 100 {
            performanceMetrics.removeFirst(performanceMetrics.count - 100)
        }

        if configuration.logPerformance {
            let retryInfo = metrics.retryCount > 0 ? " (retries: \(metrics.retryCount))" : ""
            log(
                .info,
                "Performance: \(metrics.operationName) completed in \(String(format: "%.3f", metrics.duration))s\(retryInfo)"
            )
        }

        notifyObservers(.performance(metrics))
    }

    public func getPerformanceMetrics() -> [PerformanceMetrics] {
        return performanceMetrics
    }

    public func clearPerformanceMetrics() {
        performanceMetrics.removeAll()
    }

    private func notifyObservers(_ event: SpotifyClientEvent) {
        guard !observers.isEmpty else { return }
        for handler in observers.values {
            handler(event)
        }
    }

    private func makeRequestContext(token: RequestLogToken, request: URLRequest)
        -> RequestLogContext
    {
        let method = request.httpMethod ?? "GET"
        let rawHeaders = request.allHTTPHeaderFields ?? [:]
        let headers = sanitizeHeaders(rawHeaders)
        let bodyData = request.httpBody ?? Data()
        let contentType = findContentType(in: rawHeaders)

        return RequestLogContext(
            token: token,
            method: method,
            url: request.url,
            headers: headers,
            bodyBytes: bodyData.count,
            bodyPreview: makeBodyPreview(
                bodyData,
                contentType: contentType,
                allowSensitive: configuration.allowSensitivePayloads
            )
        )
    }

    private func makeResponseContext(
        token: RequestLogToken?,
        response: URLResponse?,
        data: Data?,
        error: Error?
    ) -> ResponseLogContext {
        let httpResponse = response as? HTTPURLResponse
        let rawHeaders =
            httpResponse?.allHeaderFields.reduce(into: [String: String]()) {
                partialResult, header in
                if let key = header.key as? String,
                    let value = header.value as? CustomStringConvertible
                {
                    partialResult[key] = value.description
                }
            } ?? [:]
        let headers = sanitizeHeaders(rawHeaders)

        let dataBytes = data?.count ?? 0
        let bodyPreview = makeBodyPreview(
            data,
            contentType: findContentType(in: rawHeaders),
            allowSensitive: configuration.allowSensitivePayloads
        )

        return ResponseLogContext(
            token: token,
            statusCode: httpResponse?.statusCode,
            url: httpResponse?.url,
            headers: headers,
            dataBytes: dataBytes,
            bodyPreview: bodyPreview,
            errorDescription: error?.localizedDescription
        )
    }

    private func makeBodyPreview(
        _ data: Data?,
        contentType: String?,
        allowSensitive: Bool
    ) -> String? {
        guard let data, !data.isEmpty else { return nil }

        guard allowSensitive else {
            return Self.redactedBodyPlaceholder
        }

        if isLikelyJSON(data: data, contentType: contentType),
            let sanitizedJSON = sanitizeJSONPreview(data)
        {
            if shouldRedactBody(preview: sanitizedJSON, contentType: contentType) {
                return Self.redactedBodyPlaceholder
            }
            return sanitizedJSON
        }

        let limit = min(data.count, 1024)
        let previewData = data.prefix(limit)
        if let string = String(data: previewData, encoding: .utf8) {
            if shouldRedactBody(preview: string, contentType: contentType) {
                return "<redacted>"
            }
            return string
        }
        return "<binary data>"
    }

    private func sanitizeJSONPreview(_ data: Data) -> String? {
        guard var jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }

        jsonObject = sanitizeJSONValue(jsonObject)

        if let string = jsonObject as? String {
            return string
        }
        if let number = jsonObject as? NSNumber {
            return number.stringValue
        }
        if jsonObject is NSNull {
            return "null"
        }

        guard JSONSerialization.isValidJSONObject(jsonObject),
            let sanitizedData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.sortedKeys]
            )
        else {
            return nil
        }

        let limit = min(sanitizedData.count, 1024)
        var preview = String(data: sanitizedData.prefix(limit), encoding: .utf8)
        if sanitizedData.count > limit {
            preview? += "…"
        }
        return preview
    }

    private func sanitizeJSONValue(_ value: Any) -> Any {
        if var dictionary = value as? [String: Any] {
            for (key, nested) in dictionary {
                let lowered = key.lowercased()
                if lowered == "items" {
                    dictionary[key] = [Self.redactedJSONValue]
                    continue
                }
                if Self.sensitiveJSONKeys.contains(lowered) {
                    dictionary[key] = Self.redactedJSONValue
                } else {
                    dictionary[key] = sanitizeJSONValue(nested)
                }
            }
            return dictionary
        } else if let array = value as? [Any] {
            var sanitized: [Any] = []
            sanitized.reserveCapacity(array.count)
            for element in array {
                sanitized.append(sanitizeJSONValue(element))
            }
            return sanitized
        } else {
            return value
        }
    }

    private func isLikelyJSON(data: Data, contentType: String?) -> Bool {
        if let contentType,
            contentType.lowercased().contains("json")
        {
            return true
        }
        if let snippet = String(data: data.prefix(16), encoding: .utf8) {
            let trimmed = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
                return true
            }
        }
        return false
    }

    private func sanitizeHeaders(_ headers: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (key, value) in headers {
            if isSensitiveHeader(key) {
                sanitized[key] = redactedHeaderValue(value)
            } else {
                sanitized[key] = value
            }
        }
        return sanitized
    }

    private func isSensitiveHeader(_ key: String) -> Bool {
        let normalized = key.lowercased()
        return Self.sensitiveHeaderNames.contains(normalized)
    }

    private func redactedHeaderValue(_ value: String) -> String {
        if let space = value.firstIndex(of: " ") {
            let prefix = value[..<space]
            return "\(prefix) <redacted>"
        }
        return "<redacted>"
    }

    private func shouldRedactBody(preview: String, contentType: String?) -> Bool {
        if let contentType,
            contentType.lowercased().contains("multipart")
                || contentType.lowercased().contains("form")
        {
            return true
        }

        let lowercase = preview.lowercased()
        for keyword in Self.sensitiveBodyKeywords {
            if lowercase.contains(keyword) {
                return true
            }
        }
        return false
    }

    private func findContentType(in headers: [String: String]) -> String? {
        for (key, value) in headers {
            if key.caseInsensitiveCompare("Content-Type") == .orderedSame {
                return value
            }
        }
        return nil
    }

    private func emitExposureWarning(_ reason: String) {
        guard !hasLoggedExposureWarning else { return }
        hasLoggedExposureWarning = true
        let warning =
            "Debug logging may expose sensitive data (\(reason)). Avoid enabling in production builds."
        #if canImport(os)
            osLog.warning("\(warning)")
        #else
            print("[WARN] DebugLogger - \(warning)")
        #endif
    }

    private func emitObserverWarningIfNeeded() {
        guard !hasLoggedObserverWarning else { return }
        hasLoggedObserverWarning = true
        emitExposureWarning("Observers receive request/response metadata")
    }

    private func enforceProductionSafety(for config: DebugConfiguration) -> DebugConfiguration {
        guard !isDebugBuild else { return config }

        var sanitized = config
        var wasModified = false

        if config.logLevel.rawValue > DebugLogLevel.info.rawValue {
            sanitized = sanitized.overriding(logLevel: .info)
            wasModified = true
        }

        if config.logRequests || config.logResponses {
            sanitized = sanitized.overriding(logRequests: false, logResponses: false)
            wasModified = true
        }

        if config.allowSensitivePayloads {
            sanitized = sanitized.overriding(allowSensitivePayloads: false)
            wasModified = true
        }

        if wasModified {
            emitProductionRestrictionWarning()
        }

        return sanitized
    }

    private func emitProductionRestrictionWarning() {
        guard !hasLoggedProductionRestriction else { return }
        hasLoggedProductionRestriction = true
        let warning =
            "Sensitive debug logging features are disabled in release builds. Enable DEBUG to log requests/responses."
        #if canImport(os)
            osLog.warning("\(warning)")
        #else
            print("[WARN] DebugLogger - \(warning)")
        #endif
    }

    private static let sensitiveHeaderNames: Set<String> = [
        "authorization",
        "proxy-authorization",
        "cookie",
        "set-cookie",
        "x-spotify-authorization",
        "x-api-key",
    ]

    private static let sensitiveBodyKeywords: [String] = [
        "access_token",
        "refresh_token",
        "token",
        "password",
        "secret",
        "authorization",
    ]

    private static let sensitiveJSONKeys: Set<String> = [
        "display_name",
        "email",
    ]

    internal static let redactedBodyPlaceholder =
        "<payload redacted – set DebugConfiguration.allowSensitivePayloads = true to log bodies>"

    private static let redactedJSONValue = "<redacted>"
}

extension DebugConfiguration {
    fileprivate func overriding(
        logLevel: DebugLogLevel? = nil,
        logRequests: Bool? = nil,
        logResponses: Bool? = nil,
        logPerformance: Bool? = nil,
        logNetworkRetries: Bool? = nil,
        logTokenOperations: Bool? = nil,
        allowSensitivePayloads: Bool? = nil
    ) -> DebugConfiguration {
        DebugConfiguration(
            logLevel: logLevel ?? self.logLevel,
            logRequests: logRequests ?? self.logRequests,
            logResponses: logResponses ?? self.logResponses,
            logPerformance: logPerformance ?? self.logPerformance,
            logNetworkRetries: logNetworkRetries ?? self.logNetworkRetries,
            logTokenOperations: logTokenOperations ?? self.logTokenOperations,
            allowSensitivePayloads: allowSensitivePayloads ?? self.allowSensitivePayloads
        )
    }
}

/// Performance measurement helper
public struct PerformanceMeasurement {
    private let startTime: Date
    private let operationName: String
    private var retryCount: Int = 0
    private let logger: DebugLogger

    public init(_ operationName: String, logger: DebugLogger) {
        self.operationName = operationName
        self.startTime = Date()
        self.logger = logger
    }

    public mutating func incrementRetryCount() {
        retryCount += 1
    }

    public func getRetryCount() -> Int {
        return retryCount
    }

    public func finish() async {
        let duration = Date().timeIntervalSince(startTime)
        let metrics = PerformanceMetrics(
            operationName: operationName,
            duration: duration,
            retryCount: retryCount
        )
        await logger.recordPerformance(metrics)
    }
}

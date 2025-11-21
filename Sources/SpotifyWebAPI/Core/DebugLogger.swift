import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

#if canImport(os)
    import os
#endif

/// Debug logging levels for SpotifyWebAPI
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

/// Debug configuration for SpotifyWebAPI
public struct DebugConfiguration: Sendable {
    public let logLevel: DebugLogLevel
    public let logRequests: Bool
    public let logResponses: Bool
    public let logPerformance: Bool
    public let logNetworkRetries: Bool
    public let logTokenOperations: Bool

    public init(
        logLevel: DebugLogLevel = .off,
        logRequests: Bool = false,
        logResponses: Bool = false,
        logPerformance: Bool = false,
        logNetworkRetries: Bool = false,
        logTokenOperations: Bool = false
    ) {
        self.logLevel = logLevel
        self.logRequests = logRequests
        self.logResponses = logResponses
        self.logPerformance = logPerformance
        self.logNetworkRetries = logNetworkRetries
        self.logTokenOperations = logTokenOperations
    }

    public static let disabled = DebugConfiguration()

    public static let verbose = DebugConfiguration(
        logLevel: .verbose,
        logRequests: true,
        logResponses: true,
        logPerformance: true,
        logNetworkRetries: true,
        logTokenOperations: true
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

/// Debug logger for SpotifyWebAPI
@globalActor
public actor DebugLogger {
    public static let shared = DebugLogger()
    
    #if DEBUG
    /// Test-only logger instance to avoid contaminating shared state during tests
    internal static let testInstance = DebugLogger()
    #endif

    private var configuration: DebugConfiguration = .disabled
    private var performanceMetrics: [PerformanceMetrics] = []

    #if canImport(os)
        private let osLog = Logger(subsystem: "com.spotifywebapi", category: "debug")
    #endif

    private init() {}

    public func configure(_ config: DebugConfiguration) {
        self.configuration = config
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

    public func logRequest(_ request: URLRequest) {
        guard configuration.logRequests else { return }

        var message =
            "HTTP \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let headerString = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            message += "\nHeaders: \(headerString)"
        }

        if let body = request.httpBody, !body.isEmpty {
            let bodyString = String(data: body, encoding: .utf8) ?? "<binary data>"
            message += "\nBody: \(bodyString)"
        }

        log(.debug, "Request: \(message)")
    }

    public func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard configuration.logResponses else { return }

        var message = ""

        if let httpResponse = response as? HTTPURLResponse {
            message += "HTTP \(httpResponse.statusCode)"
            if let url = httpResponse.url {
                message += " \(url.absoluteString)"
            }
        }

        if let data = data {
            message += "\nData: \(data.count) bytes"
            if data.count < 1000, let bodyString = String(data: data, encoding: .utf8) {
                message += " - \(bodyString)"
            }
        }

        if let error = error {
            message += "\nError: \(error.localizedDescription)"
        }

        log(.debug, "Response: \(message)")
    }

    public func logNetworkRetry(attempt: Int, error: Error, delay: TimeInterval) {
        guard configuration.logNetworkRetries else { return }
        log(
            .info,
            "Network retry attempt \(attempt) after \(String(format: "%.2f", delay))s - \(error.localizedDescription)"
        )
    }

    public func logTokenOperation(_ operation: String, success: Bool) {
        guard configuration.logTokenOperations else { return }
        let status = success ? "SUCCESS" : "FAILED"
        log(.info, "Token operation: \(operation) - \(status)")
    }

    public func recordPerformance(_ metrics: PerformanceMetrics) {
        performanceMetrics.append(metrics)

        // Keep only last 100 metrics
        if performanceMetrics.count > 100 {
            performanceMetrics.removeFirst(performanceMetrics.count - 100)
        }

        guard configuration.logPerformance else { return }

        let retryInfo = metrics.retryCount > 0 ? " (retries: \(metrics.retryCount))" : ""
        log(
            .info,
            "Performance: \(metrics.operationName) completed in \(String(format: "%.3f", metrics.duration))s\(retryInfo)"
        )
    }

    public func getPerformanceMetrics() -> [PerformanceMetrics] {
        return performanceMetrics
    }

    public func clearPerformanceMetrics() {
        performanceMetrics.removeAll()
    }
}

/// Performance measurement helper
public struct PerformanceMeasurement {
    private let startTime: Date
    private let operationName: String
    private var retryCount: Int = 0
    private let logger: DebugLogger

    public init(_ operationName: String, logger: DebugLogger = DebugLogger.shared) {
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

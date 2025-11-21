import Foundation
@testable import SpotifyWebAPI

/// Helper for managing debug logger state during tests
@MainActor
struct TestDebugHelper {
    
    /// Configure the test logger with disabled performance logging for optimal test performance
    static func configureForTests() async {
        #if DEBUG
        let testConfig = DebugConfiguration.disabled
        await DebugLogger.testInstance.configure(testConfig)
        await DebugLogger.testInstance.clearPerformanceMetrics()
        
        // Also disable the shared logger to prevent any interference
        await DebugLogger.shared.configure(testConfig)
        await DebugLogger.shared.clearPerformanceMetrics()
        #endif
    }
    
    /// Clear all metrics from both test and shared loggers
    static func clearAllMetrics() async {
        #if DEBUG
        await DebugLogger.testInstance.clearPerformanceMetrics()
        #endif
        await DebugLogger.shared.clearPerformanceMetrics()
    }
    
    /// Get the appropriate logger for tests
    static var testLogger: DebugLogger {
        #if DEBUG
        return DebugLogger.testInstance
        #else
        return DebugLogger.shared
        #endif
    }
}
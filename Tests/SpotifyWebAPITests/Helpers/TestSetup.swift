import Foundation
@testable import SpotifyWebAPI

/// Centralized test environment utilities.
@MainActor
enum TestEnvironment {

    /// Apply a consistent debug logger configuration for tests.
    static func bootstrap() async {
        await configureDebugLogging()
        await clearMetrics()
    }

    /// Resets any recorded performance metrics between suites.
    static func clearMetrics() async {
        await DebugLogger.testInstance.clearPerformanceMetrics()
        await DebugLogger.shared.clearPerformanceMetrics()
    }

    /// Provides the logger that tests should use.
    static var logger: DebugLogger {
        DebugLogger.testInstance
    }

    private static func configureDebugLogging() async {
        let config = DebugConfiguration.disabled
        await DebugLogger.testInstance.configure(config)
        await DebugLogger.shared.configure(config)
    }
}

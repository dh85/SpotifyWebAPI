import Foundation

@testable import SpotifyKit

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
    await logger.clearPerformanceMetrics()
  }

  /// Provides the logger that tests should use.
  static let logger = DebugLogger()

  private static func configureDebugLogging() async {
    let config = DebugConfiguration.disabled
    await logger.configure(config)
  }
}

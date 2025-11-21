import Foundation
@testable import SpotifyWebAPI

/// Global test setup to optimize performance
@MainActor
struct TestSetup {
    
    /// Configure all tests for optimal performance
    static func configure() async {
        await TestDebugHelper.configureForTests()
    }
    
    /// Clear metrics between test suites
    static func clearMetrics() async {
        await TestDebugHelper.clearAllMetrics()
    }
}

/// Test suite initializer to ensure consistent setup
extension TestSetup {
    
    /// Call this in test suite init() methods
    static func initializeSuite() async {
        await configure()
        await clearMetrics()
    }
}
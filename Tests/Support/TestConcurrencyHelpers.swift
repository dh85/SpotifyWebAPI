import Foundation
import Testing

@testable import SpotifyWebAPI

// MARK: - Concurrency Test Helpers

/// Actor for recording async operations in concurrency tests.
actor OffsetRecorder {
    private var offsets: [Int] = []

    func record(_ offset: Int) {
        offsets.append(offset)
    }

    func snapshot() -> [Int] {
        offsets
    }
}

/// Creates a test token with configurable parameters.
///
/// Useful for concurrency tests that need to create many tokens quickly.
func makeTestToken(
    accessToken: String = "TEST_ACCESS",
    refreshToken: String? = "TEST_REFRESH",
    expiresIn: TimeInterval = 3600,
    scope: String? = nil
) -> SpotifyTokens {
    SpotifyTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: Date().addingTimeInterval(expiresIn),
        scope: scope,
        tokenType: "Bearer"
    )
}

/// Executes a task, waits briefly, cancels it, and asserts cancellation behavior.
///
/// - Parameters:
///   - delayBeforeCancel: How long to wait before canceling (default: 50ms)
///   - task: The task to test for cancellation
///   - expectation: What to expect from the cancelled task
func assertTaskCancellation<T: Sendable>(
    delayBeforeCancel: Duration = .milliseconds(50),
    task: Task<T, Error>,
    expectation: @escaping @Sendable (Result<T, Error>) -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    try await Task.sleep(for: delayBeforeCancel)
    task.cancel()

    let result = await task.result
    #expect(expectation(result), sourceLocation: sourceLocation)
}

/// Asserts that a task result represents cancellation.
func expectCancellation<T>(
    _ result: Result<T, Error>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch result {
    case .success:
        Issue.record("Expected task to be cancelled", sourceLocation: sourceLocation)
    case .failure(let error):
        if !(error is CancellationError) {
            Issue.record("Expected CancellationError, got \(error)", sourceLocation: sourceLocation)
        }
    }
}

/// Asserts that a task result is success with an optional value check.
func expectTaskSuccess<T>(
    _ result: Result<T, Error>,
    where predicate: ((T) -> Bool)? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch result {
    case .success(let value):
        if let predicate, !predicate(value) {
            Issue.record(
                "Task succeeded but value didn't match predicate", sourceLocation: sourceLocation)
        }
    case .failure(let error):
        Issue.record("Expected success, got error: \(error)", sourceLocation: sourceLocation)
    }
}

/// Runs multiple concurrent tasks and collects their results.
///
/// - Parameters:
///   - count: Number of concurrent tasks to run
///   - operation: The operation to perform in each task
/// - Returns: Array of results from all tasks
func runConcurrentTasks<T: Sendable>(
    count: Int,
    operation: @escaping @Sendable () async throws -> T
) async throws -> [T] {
    try await withThrowingTaskGroup(of: T.self) { group in
        for _ in 0..<count {
            group.addTask {
                try await operation()
            }
        }

        var results: [T] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}

// MARK: - Reusable Test Actors

/// Generic actor for tracking events in tests.
actor EventCollector<T: Sendable> {
    private(set) var events: [T] = []
    private(set) var count: Int = 0

    func record(_ event: T) {
        events.append(event)
        count += 1
    }

    func reset() {
        events.removeAll()
        count = 0
    }
}

/// Actor for safely collecting progress reports from callbacks.
actor ProgressHolder {
    private(set) var progressReports: [BatchProgress] = []

    func add(_ progress: BatchProgress) {
        progressReports.append(progress)
    }

    func reset() {
        progressReports.removeAll()
    }
}

/// Actor for tracking token refresh events.
actor TokenRefreshTracker {
    var willStartCalled = false
    var willStartInfo: TokenRefreshInfo?
    var didSucceedCalled = false
    var succeededTokens: SpotifyTokens?
    var didFailCalled = false
    var failedError: Error?
    var callSequence: [String] = []

    func recordWillStart(_ info: TokenRefreshInfo) {
        willStartCalled = true
        willStartInfo = info
        callSequence.append("willStart")
    }

    func recordDidSucceed(_ tokens: SpotifyTokens) {
        didSucceedCalled = true
        succeededTokens = tokens
        callSequence.append("didSucceed")
    }

    func recordDidFail(_ error: Error) {
        didFailCalled = true
        failedError = error
        callSequence.append("didFail")
    }

    func reset() {
        willStartCalled = false
        willStartInfo = nil
        didSucceedCalled = false
        succeededTokens = nil
        didFailCalled = false
        failedError = nil
        callSequence = []
    }
}

/// Actor for tracking token expiration callbacks.
actor TokenExpirationTracker {
    var wasCalled = false
    var expiresIn: TimeInterval?
    var callCount = 0

    func recordExpiration(_ time: TimeInterval) {
        wasCalled = true
        expiresIn = time
        callCount += 1
    }

    func recordExpiration() {
        wasCalled = true
        callCount += 1
    }

    func reset() {
        wasCalled = false
        expiresIn = nil
        callCount = 0
    }
}

/// Actor for tracking cancellation in async operations.
actor CancellationTracker {
    private var started = false
    private var cancelled = false

    func markStarted() {
        started = true
    }

    func markCancelled() {
        cancelled = true
    }

    func waitForStart(timeout: Duration = .milliseconds(250)) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while started == false {
            if clock.now >= deadline { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return started
    }

    func waitForCancellation(timeout: Duration = .milliseconds(250)) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while cancelled == false {
            if clock.now >= deadline { break }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return cancelled
    }
}

/// Actor for recording fetch operations in pagination tests.
actor FetchRecorder {
    private(set) var count: Int = 0
    private var waiters: [CountWaiter] = []

    private struct CountWaiter {
        let target: Int
        let continuation: CheckedContinuation<Int, Never>
        let handler: (@Sendable (Int) -> Void)?
    }

    func record(offset: Int) {
        _ = offset
        count += 1
        fulfillWaiters()
    }

    func waitForCount(
        atLeast target: Int,
        onSatisfy: (@Sendable (Int) -> Void)? = nil
    ) async -> Int {
        if count >= target {
            onSatisfy?(count)
            return count
        }

        return await withCheckedContinuation { continuation in
            waiters.append(
                CountWaiter(
                    target: target,
                    continuation: continuation,
                    handler: onSatisfy
                )
            )
        }
    }

    private func fulfillWaiters() {
        guard !waiters.isEmpty else { return }

        var remaining: [CountWaiter] = []
        for waiter in waiters {
            if count >= waiter.target {
                waiter.continuation.resume(returning: count)
                waiter.handler?(count)
            } else {
                remaining.append(waiter)
            }
        }

        waiters = remaining
    }
}

// MARK: - Test Timing Constants

/// Standard short delay for test synchronization.
let testShortDelay: Duration = .milliseconds(10)

/// Standard medium delay for test operations.
let testMediumDelay: Duration = .milliseconds(50)

/// Standard long delay for test timeouts.
let testLongDelay: Duration = .milliseconds(100)

// MARK: - Progress Testing Helpers

/// Executes a batch operation and collects progress reports.
func withProgressTracking<T>(
    operation: (@escaping (BatchProgress) -> Void) async throws -> T
) async throws -> (result: T, progress: [BatchProgress]) {
    let holder = ProgressHolder()
    let result = try await operation { progress in
        Task {
            await holder.add(progress)
        }
    }
    let progress = await holder.progressReports
    return (result, progress)
}

import Foundation
import Testing

@testable import SpotifyKit

/// Collects instrumentation events emitted through ``SpotifyClientObserver``.
actor InstrumentationEventCollector {
    private var events: [SpotifyClientEvent] = []

    func append(_ event: SpotifyClientEvent) {
        events.append(event)
    }

    func waitForEvents(
        count: Int,
        timeout: Duration = .milliseconds(250)
    ) async -> [SpotifyClientEvent] {
        if events.count >= count {
            return events
        }

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while events.count < count {
            let now = clock.now
            if now >= deadline {
                break
            }

            let remaining = deadline - now
            let sleep = remaining < .milliseconds(5) ? remaining : .milliseconds(5)
            try? await Task.sleep(for: sleep)
        }

        return events
    }

    func waitForEvent<T>(
        timeout: Duration = .milliseconds(250),
        transform: @Sendable (SpotifyClientEvent) -> T?
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
            let sleep = remaining < .milliseconds(5) ? remaining : .milliseconds(5)
            try? await Task.sleep(for: sleep)
        }
    }

    func snapshot() -> [SpotifyClientEvent] {
        events
    }
}

/// Convenience observer that forwards events into an ``InstrumentationEventCollector``.
struct InstrumentationObserver: SpotifyClientObserver {
    let collector: InstrumentationEventCollector

    func receive(_ event: SpotifyClientEvent) {
        Task { await collector.append(event) }
    }
}

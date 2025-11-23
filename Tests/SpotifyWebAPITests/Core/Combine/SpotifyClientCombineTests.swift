#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyWebAPI

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("SpotifyClient Combine Helper Tests")
    @MainActor
    struct SpotifyClientCombineTests {

        @Test("makePublisher emits values")
        func makePublisherEmitsValue() async throws {
            let (client, _) = makeUserAuthClient()
            let publisher = client.makePublisher { "value" }

            let result = try await awaitFirstValue(publisher)
            #expect(result == "value")
        }

        @Test("makePublisher propagates errors")
        func makePublisherPropagatesErrors() async {
            enum SampleError: Error, Equatable { case boom }

            let (client, _) = makeUserAuthClient()
            let publisher = client.makePublisher { () -> Int in
                throw SampleError.boom
            }

            do {
                _ = try await awaitFirstValue(publisher)
                Issue.record("Expected makePublisher to throw")
            } catch let error as SampleError {
                #expect(error == .boom)
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test("makePublisher cancels underlying task when subscription cancels")
        func makePublisherCancelsTaskOnCancellation() async {
            let (client, _) = makeUserAuthClient()
            let tracker = CancellationTracker()

            let publisher = client.makePublisher { () -> Int in
                await tracker.markStarted()
                do {
                    try await Task.sleep(for: .seconds(5))
                    Issue.record("Cancellation test should not finish the task")
                    return 1
                } catch is CancellationError {
                    await tracker.markCancelled()
                    throw CancellationError()
                } catch {
                    throw error
                }
            }

            let cancellable = publisher.sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in Issue.record("Cancellation test should not receive a value") }
            )

            let didStart = await tracker.waitForStart()
            #expect(didStart)

            cancellable.cancel()

            let didCancel = await tracker.waitForCancellation()
            #expect(didCancel)
        }
    }

    private actor CancellationTracker {
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

#endif

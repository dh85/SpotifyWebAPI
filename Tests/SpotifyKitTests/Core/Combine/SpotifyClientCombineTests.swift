#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyKit

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

        @Test("observerPublisher emits SpotifyClientEvents")
        func observerPublisherEmitsEvents() async throws {
            let backend = MockTokenAuthenticator(token: AuthTestFixtures.sampleTokens())
            let client = SpotifyClient<UserAuthCapability>(backend: backend)

                        // Filter for our specific test event to avoid noise from other tests
            let performancePublisher = client.observerPublisher(bufferSize: 4)
                .filter { event in
                    if case .performance(let metrics) = event, metrics.operationName == "observer-test" {
                        return true
                    }
                    return false
                }
                .setFailureType(to: Error.self)

            let metrics = PerformanceMetrics(operationName: "observer-test", duration: 0.1)
            let logger = DebugLogger.telemetryLogger()

            // Emit repeatedly to handle race condition where observer registration is async
            let emitterTask = Task {
                while !Task.isCancelled {
                    await logger.emit(.performance(metrics))
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }

            let emitted = try await awaitFirstValue(performancePublisher)
            emitterTask.cancel()
            
            guard case .performance(let emittedMetrics) = emitted else {
                Issue.record("Expected performance event")
                return
            }
            
            #expect(emittedMetrics.operationName == metrics.operationName)
        }
    }

#endif

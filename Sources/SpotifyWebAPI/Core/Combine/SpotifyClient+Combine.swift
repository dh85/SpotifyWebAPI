#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension SpotifyClient {

        /// Bridges an async operation that captures the client into an `AnyPublisher`.
        ///
        /// The returned publisher lazily starts a `Task` when subscribed to and
        /// automatically cancels the task if the subscription is cancelled.
        nonisolated func makePublisher<Output: Sendable>(
            priority: TaskPriority? = nil,
            _ operation: @escaping @Sendable () async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            Deferred {
                makeTaskPublisher(priority: priority, operation)
            }
            .eraseToAnyPublisher()
        }
    }

    // MARK: - Helpers

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    private func makeTaskPublisher<Output: Sendable>(
        priority: TaskPriority?,
        _ operation: @escaping @Sendable () async throws -> Output
    ) -> Publishers.HandleEvents<Future<Output, Error>> {
        let taskReference = TaskReference()

        let future = Future<Output, Error> { promise in
            let promiseBox = PromiseBox(promise)

            let task = Task(priority: priority) {
                defer { taskReference.markFinished() }
                do {
                    let value = try await operation()
                    if Task.isCancelled || taskReference.isCancelled { return }
                    promiseBox.succeed(value)
                } catch is CancellationError {
                    if taskReference.isCancelled { return }
                    promiseBox.fail(CancellationError())
                } catch {
                    if taskReference.isCancelled { return }
                    promiseBox.fail(error)
                }
            }

            taskReference.store(task)
        }

        return future.handleEvents(receiveCancel: {
            taskReference.cancel()
        })
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    private final class TaskReference: @unchecked Sendable {
        private let lock = NSLock()
        private var task: Task<Void, Never>?
        private var cancelled = false

        func store(_ task: Task<Void, Never>) {
            lock.lock()
            self.task = task
            cancelled = false
            lock.unlock()
        }

        func cancel() {
            lock.lock()
            cancelled = true
            let task = self.task
            self.task = nil
            lock.unlock()
            task?.cancel()
        }

        func markFinished() {
            lock.lock()
            self.task = nil
            lock.unlock()
        }

        var isCancelled: Bool {
            lock.lock()
            let value = cancelled
            lock.unlock()
            return value
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    private final class PromiseBox<Output>: @unchecked Sendable {
        private let promise: (Result<Output, Error>) -> Void

        init(_ promise: @escaping (Result<Output, Error>) -> Void) {
            self.promise = promise
        }

        func succeed(_ value: Output) {
            promise(.success(value))
        }

        func fail(_ error: Error) {
            promise(.failure(error))
        }
    }

#endif

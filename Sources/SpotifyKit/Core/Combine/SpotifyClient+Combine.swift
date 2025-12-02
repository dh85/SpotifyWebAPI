#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine utilities that bridge ``SpotifyClient`` async operations into publishers.
  ///
  /// ## Async Counterparts
  /// Every publisher created through these helpers forwards to the underlying async call, so you
  /// can swap between paradigms without duplicating business logic.
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
      CombineTaskPublisher.make(priority: priority, operation: operation)
    }

    /// Emits ``SpotifyClientEvent`` values through a Combine publisher by wiring up a
    /// transient ``SpotifyClientObserver``.
    ///
    /// ## Async Counterpart
    /// If you prefer AsyncSequence, register an observer manually via ``addObserver(_:)`` and
    /// stream events through `AsyncStream`. This publisher wraps the same observer APIs so loggers
    /// and telemetry can swap paradigms without changing instrumentation wiring.
    ///
    /// - Parameter bufferSize: The size of the buffer for the publisher. Defaults to 64.
    /// - Returns: A publisher that emits `SpotifyClientEvent` values.
    public nonisolated func observerPublisher(
      bufferSize: Int = 64
    ) -> AnyPublisher<SpotifyClientEvent, Never> {
      Deferred { [client = self] in
        let subject = PassthroughSubject<SpotifyClientEvent, Never>()
        let bridge = ObserverBridge(client: client, subject: subject)

        let publisher: AnyPublisher<SpotifyClientEvent, Never>
        if bufferSize > 0 {
          publisher =
            subject
            .buffer(
              size: bufferSize,
              prefetch: .keepFull,
              whenFull: .dropOldest
            )
            .eraseToAnyPublisher()
        } else {
          publisher = subject.eraseToAnyPublisher()
        }

        return
          publisher
          .handleEvents(
            receiveCompletion: { _ in bridge.cancel() },
            receiveCancel: { bridge.cancel() }
          )
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
    }
  }

  // MARK: - Observer Bridge

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  private final class ObserverBridge<Capability: Sendable>: @unchecked Sendable {
    private let client: SpotifyClient<Capability>
    private weak var subject: PassthroughSubject<SpotifyClientEvent, Never>?
    private var observerToken: DebugLogObserver?
    private var cancelled = false
    private let lock = NSLock()

    init(client: SpotifyClient<Capability>, subject: PassthroughSubject<SpotifyClientEvent, Never>)
    {
      self.client = client
      self.subject = subject
      Task { await self.registerObserver() }
    }

    deinit {
      cancel()
    }

    func cancel() {
      let token: DebugLogObserver?
      lock.lock()
      if cancelled {
        lock.unlock()
        return
      }
      cancelled = true
      token = observerToken
      observerToken = nil
      self.subject = nil
      lock.unlock()

      if let token {
        Task { await client.removeObserver(token) }
      }
    }

    private func registerObserver() async {
      let proxy = ObserverProxy { [weak self] event in
        self?.forward(event)
      }
      let token = await client.addObserver(proxy)
      storeToken(token)
    }

    private func storeToken(_ token: DebugLogObserver) {
      lock.lock()
      if cancelled {
        lock.unlock()
        Task { await client.removeObserver(token) }
      } else {
        observerToken = token
        lock.unlock()
      }
    }

    private func forward(_ event: SpotifyClientEvent) {
      let subjectToUse: PassthroughSubject<SpotifyClientEvent, Never>?
      lock.lock()
      if !cancelled, let subject = subject {
        subjectToUse = subject
      } else {
        subjectToUse = nil
      }
      lock.unlock()

      if let subject = subjectToUse {
        DispatchQueue.main.async {
          subject.send(event)
        }
      }
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  private struct ObserverProxy: SpotifyClientObserver {
    let handler: @Sendable (SpotifyClientEvent) -> Void

    func receive(_ event: SpotifyClientEvent) {
      handler(event)
    }
  }

#endif

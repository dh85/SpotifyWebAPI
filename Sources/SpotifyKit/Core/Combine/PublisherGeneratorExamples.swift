#if canImport(Combine)
  import Combine
  import Foundation

  /// Example demonstrating the new publisher generators to reduce boilerplate.
  ///
  /// This file shows side-by-side comparisons of old vs new approaches.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension TracksService where Capability: PublicSpotifyCapability {

    // MARK: - Example 1: Simple getter with no parameters

    // Old approach (still works):
    /*
    public func getPublisher(
        _ id: String,
        market: String? = nil,
        priority: TaskPriority? = nil
    ) -> AnyPublisher<Track, Error> {
        catalogItemPublisher(id: id, market: market, priority: priority) {
            service, trackID, market in
            try await service.get(trackID, market: market)
        }
    }
    */

    // New approach using makePublisher:
    // Note: This demonstrates the concept but the actual implementation
    // remains in TracksService+Combine.swift using the existing helpers
    // since they provide semantic clarity for catalog items.

    // MARK: - Example 2: Method with optional parameters

    // The new helpers work best for simple forwarding cases.
    // For complex parameter handling, the existing specialized helpers
    // (catalogItemPublisher, librarySavedPublisher, etc.) are still preferred
    // as they encode domain semantics.
  }

  /// Example showing when to use each approach
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension PlayerService where Capability == UserAuthCapability {

    // MARK: - Best Use Cases for makePublisher

    // ✅ GOOD: Simple method with no parameters
    /*
    public func devicesPublisher(
        priority: TaskPriority? = nil
    ) -> AnyPublisher<[SpotifyDevice], Error> {
        // This is cleaner than the closure version
        makePublisher(priority: priority, operation: devices)
    }
    */

    // ✅ GOOD: Method reference when parameter types align
    /*
    public func queuePublisher(
        priority: TaskPriority? = nil
    ) -> AnyPublisher<UserQueue, Error> {
        makePublisher(priority: priority, operation: queue)
    }
    */

    // ⚠️ MIXED: Works but closure might be clearer for optional parameters
    /*
    public func pausePublisher(
        deviceID: String? = nil,
        priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
        // This works:
        makePublisher(deviceID, priority: priority, operation: Self.pause)
    
        // But this might be clearer due to named parameter:
        publisher(priority: priority) { service in
            try await service.pause(deviceID: deviceID)
        }
    }
    */

    // ❌ AVOID: Complex parameter transformation
    /*
    public func statePublisher(
        market: String? = nil,
        additionalTypes: Set<AdditionalItemType>? = nil,
        priority: TaskPriority? = nil
    ) -> AnyPublisher<PlaybackState?, Error> {
        // Don't use makePublisher here - closure is clearer
        publisher(priority: priority) { service in
            try await service.state(market: market, additionalTypes: additionalTypes)
        }
    }
    */
  }

#endif

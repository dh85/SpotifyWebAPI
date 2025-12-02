#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror ``ChaptersService`` async APIs.
  ///
  /// ## Async Counterparts
  /// Reach for ``ChaptersService/get(_:market:)`` or ``ChaptersService/several(ids:market:)`` when
  /// you want async/await—the publishers here just wrap those calls.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension ChaptersService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single chapter.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the chapter.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a full `Chapter` object.
    public func getPublisher(
      _ id: String,
      market: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Chapter, Error> {
      catalogItemPublisher(id: id, market: market, priority: priority) {
        service, chapterID, market in
        try await service.get(chapterID, market: market)
      }
    }

    /// Get Spotify catalog information for several chapters identified by their Spotify IDs.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a list of `Chapter` objects.
    public func severalPublisher(
      ids: [String],
      market: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Chapter], Error> {
      catalogCollectionPublisher(ids: ids, market: market, priority: priority) {
        service, ids, market in
        try await service.several(ids: ids, market: market)
      }
    }
  }

#endif

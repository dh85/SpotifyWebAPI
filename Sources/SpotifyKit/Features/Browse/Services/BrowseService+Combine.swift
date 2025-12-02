#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror ``BrowseService`` async APIs.
  ///
  /// ## Async Counterparts
  /// When you need async/await, call helpers such as ``BrowseService/newReleases(country:limit:offset:)``.
  /// These publishers wrap those same implementations so validation and paging stay aligned.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension BrowseService where Capability: PublicSpotifyCapability {

    /// Get a list of new album releases featured in Spotify.
    /// Corresponds to: `GET /v1/browse/new-releases`
    ///
    /// - Parameters:
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of albums to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of ``SimplifiedAlbum`` items.
    public func newReleasesPublisher(
      country: String? = nil,
      limit: Int = 20,
      offset: Int = 0,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Page<SimplifiedAlbum>, Error> {
      pagedPublisher(limit: limit, offset: offset, priority: priority) {
        service, limit, offset in
        try await service.newReleases(country: country, limit: limit, offset: offset)
      }
    }

    /// Get a single category used to tag content in Spotify.
    /// Corresponds to: `GET /v1/browse/categories/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the category.
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - locale: The desired language, e.g., "es_MX".
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a single ``SpotifyCategory`` object.
    public func categoryPublisher(
      id: String,
      country: String? = nil,
      locale: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<SpotifyCategory, Error> {
      publisher(priority: priority) { service in
        try await service.category(id: id, country: country, locale: locale)
      }
    }

    /// Get a list of categories used to tag content in Spotify.
    /// Corresponds to: `GET /v1/browse/categories`
    ///
    /// - Parameters:
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - locale: The desired language, e.g., "es_MX".
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of ``SpotifyCategory`` items.
    public func categoriesPublisher(
      country: String? = nil,
      locale: String? = nil,
      limit: Int = 20,
      offset: Int = 0,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Page<SpotifyCategory>, Error> {
      pagedPublisher(limit: limit, offset: offset, priority: priority) {
        service, limit, offset in
        try await service.categories(
          country: country,
          locale: locale,
          limit: limit,
          offset: offset
        )
      }
    }

    /// Get the list of markets (countries) where Spotify is available.
    /// Corresponds to: `GET /v1/markets`
    ///
    /// - Parameter priority: The priority of the task.
    /// - Returns: A publisher that emits a list of ISO 3166-1 alpha-2 country codes.
    public func availableMarketsPublisher(
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[String], Error> {
      publisher(priority: priority) { service in
        try await service.availableMarkets()
      }
    }
  }

#endif

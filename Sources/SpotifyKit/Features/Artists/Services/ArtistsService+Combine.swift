#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror ``ArtistsService`` async APIs.
  ///
  /// ## Async Counterparts
  /// Prefer ``ArtistsService/get(_: )`` and other async variants when your codebase leans on
  /// async/await—the publisher helpers simply call into those implementations so behavior stays
  /// identical.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension ArtistsService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single artist identified by their unique Spotify ID.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a full `Artist` object.
    public func getPublisher(
      _ id: String,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Artist, Error> {
      catalogItemPublisher(id: id, priority: priority) { service, artistID, _ in
        try await service.get(artistID)
      }
    }

    /// Get Spotify catalog information for several artists based on their Spotify IDs.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a list of `Artist` objects.
    public func severalPublisher(
      ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Artist], Error> {
      catalogCollectionPublisher(ids: ids, priority: priority) { service, ids, _ in
        try await service.several(ids: ids)
      }
    }

    /// Get Spotify catalog information about an artist's albums.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - includeGroups: Filter by album types.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of `SimplifiedAlbum` items.
    public func albumsPublisher(
      for id: String,
      includeGroups: Set<AlbumGroup>? = nil,
      market: String? = nil,
      limit: Int = 20,
      offset: Int = 0,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Page<SimplifiedAlbum>, Error> {
      pagedPublisher(limit: limit, offset: offset, priority: priority) {
        service, limit, offset in
        try await service.albums(
          artistId: id,
          groups: includeGroups,
          market: market,
          limit: limit,
          offset: offset
        )
      }
    }

    /// Get Spotify catalog information about an artist's top tracks by country.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the artist.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a list of `Track` objects.
    public func topTracksPublisher(
      for id: String,
      market: String,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Track], Error> {
      makePublisher(id, market, priority: priority, operation: Self.topTracks)
    }
  }

#endif

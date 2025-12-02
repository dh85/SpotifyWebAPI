#if canImport(Combine)
  import Combine
  import Foundation

  /// Combine publishers that mirror ``UsersService`` async APIs.
  ///
  /// ## Async Counterparts
  /// When you prefer async/await, stick with calls like ``UsersService/get(_: )`` or
  /// ``UsersService/me()``—publisher helpers simply wrap the same implementations.
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension UsersService where Capability: PublicSpotifyCapability {

    /// Get public profile information for a specified user.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the user.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a `PublicUserProfile` object.
    public func getPublisher(
      _ id: String,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<PublicUserProfile, Error> {
      catalogItemPublisher(id: id, priority: priority) { service, userID, _ in
        try await service.get(userID)
      }
    }

    /// Check if one or more users are following a specified playlist.
    ///
    /// - Parameters:
    ///   - playlistID: The Spotify ID for the playlist.
    ///   - userIDs: A list of Spotify User IDs (max 5).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits an array of booleans indicating follow status.
    public func checkFollowingPublisher(
      playlist playlistID: String,
      users userIDs: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Bool], Error> {
      publisher(priority: priority) { service in
        try await service.checkFollowing(playlist: playlistID, users: userIDs)
      }
    }
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  extension UsersService where Capability == UserAuthCapability {

    /// Get detailed profile information about the current user.
    ///
    /// - Parameter priority: The priority of the task.
    /// - Returns: A publisher that emits a `CurrentUserProfile` object.
    public func mePublisher(priority: TaskPriority? = nil) -> AnyPublisher<
      CurrentUserProfile, Error
    > {
      publisher(priority: priority) { service in
        try await service.me()
      }
    }

    /// Get the current user's top artists based on calculated affinity.
    ///
    /// - Parameters:
    ///   - timeRange: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of `Artist` items.
    public func topArtistsPublisher(
      timeRange: TimeRange = .mediumTerm,
      limit: Int = 20,
      offset: Int = 0,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Page<Artist>, Error> {
      pagedPublisher(limit: limit, offset: offset, priority: priority) {
        service, limit, offset in
        try await service.topArtists(timeRange: timeRange, limit: limit, offset: offset)
      }
    }

    /// Get the current user's top tracks based on calculated affinity.
    ///
    /// - Parameters:
    ///   - timeRange: The time frame for affinity calculation. Default: `.mediumTerm`.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a paginated list of `Track` items.
    public func topTracksPublisher(
      timeRange: TimeRange = .mediumTerm,
      limit: Int = 20,
      offset: Int = 0,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Page<Track>, Error> {
      pagedPublisher(limit: limit, offset: offset, priority: priority) {
        service, limit, offset in
        try await service.topTracks(timeRange: timeRange, limit: limit, offset: offset)
      }
    }

    /// Get the current user's followed artists.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - after: The last artist ID retrieved from the previous request.
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits a cursor-based page of `Artist` items.
    public func followedArtistsPublisher(
      limit: Int = 20,
      after: String? = nil,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<CursorBasedPage<Artist>, Error> {
      publisher(priority: priority) { service in
        try await service.followedArtists(limit: limit, after: after)
      }
    }

    /// Follow one or more artists.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func followPublisher(
      artists ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.follow(artists: ids)
      }
    }

    /// Follow one or more users.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func followPublisher(
      users ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.follow(users: ids)
      }
    }

    /// Unfollow one or more artists.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func unfollowPublisher(
      artists ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.unfollow(artists: ids)
      }
    }

    /// Unfollow one or more users.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits `Void` when successful.
    public func unfollowPublisher(
      users ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<Void, Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.unfollow(users: ids)
      }
    }

    /// Check if one or more artists are followed by the current user.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 5).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits an array of booleans indicating follow status.
    public func checkFollowingPublisher(
      artists ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Bool], Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.checkFollowing(artists: ids)
      }
    }

    /// Check if one or more users are followed by the current user.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 5).
    ///   - priority: The priority of the task.
    /// - Returns: A publisher that emits an array of booleans indicating follow status.
    public func checkFollowingPublisher(
      users ids: Set<String>,
      priority: TaskPriority? = nil
    ) -> AnyPublisher<[Bool], Error> {
      libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
        try await service.checkFollowing(users: ids)
      }
    }

  }

#endif

#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension UsersService where Capability: PublicSpotifyCapability {

        public func getPublisher(
            _ id: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<PublicUserProfile, Error> {
            catalogItemPublisher(id: id, priority: priority) { service, userID, _ in
                try await service.get(userID)
            }
        }

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

        public func mePublisher(priority: TaskPriority? = nil) -> AnyPublisher<
            CurrentUserProfile, Error
        > {
            publisher(priority: priority) { service in
                try await service.me()
            }
        }

        public func topArtistsPublisher(
            range: TimeRange = .mediumTerm,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<Artist>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.topArtists(range: range, limit: limit, offset: offset)
            }
        }

        public func topTracksPublisher(
            range: TimeRange = .mediumTerm,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<Track>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.topTracks(range: range, limit: limit, offset: offset)
            }
        }

        public func followedArtistsPublisher(
            limit: Int = 20,
            after: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<CursorBasedPage<Artist>, Error> {
            publisher(priority: priority) { service in
                try await service.followedArtists(limit: limit, after: after)
            }
        }

        public func followPublisher(
            artists ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.follow(artists: ids)
            }
        }

        public func followPublisher(
            users ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.follow(users: ids)
            }
        }

        public func unfollowPublisher(
            artists ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.unfollow(artists: ids)
            }
        }

        public func unfollowPublisher(
            users ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.unfollow(users: ids)
            }
        }

        public func checkFollowingPublisher(
            artists ids: Set<String>,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[Bool], Error> {
            libraryMutationPublisher(ids: ids, priority: priority) { service, ids in
                try await service.checkFollowing(artists: ids)
            }
        }

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

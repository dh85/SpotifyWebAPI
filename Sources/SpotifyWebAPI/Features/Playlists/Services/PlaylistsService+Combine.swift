#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension PlaylistsService where Capability: PublicSpotifyCapability {

        public func getPublisher(
            _ id: String,
            market: String? = nil,
            fields: String? = nil,
            additionalTypes: Set<AdditionalItemType>? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Playlist, Error> {
            catalogItemPublisher(id: id, market: market, priority: priority) {
                service, playlistID, market in
                try await service.get(
                    playlistID,
                    market: market,
                    fields: fields,
                    additionalTypes: additionalTypes
                )
            }
        }

        public func itemsPublisher(
            _ id: String,
            market: String? = nil,
            fields: String? = nil,
            limit: Int = 20,
            offset: Int = 0,
            additionalTypes: Set<AdditionalItemType>? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<PlaylistTrackItem>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.items(
                    id,
                    market: market,
                    fields: fields,
                    limit: limit,
                    offset: offset,
                    additionalTypes: additionalTypes
                )
            }
        }

        public func allItemsPublisher(
            _ id: String,
            market: String? = nil,
            fields: String? = nil,
            additionalTypes: Set<AdditionalItemType>? = nil,
            maxItems: Int? = 5000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[PlaylistTrackItem], Error> {
            publisher(priority: priority) { service in
                try await service.allItems(
                    id,
                    market: market,
                    fields: fields,
                    additionalTypes: additionalTypes,
                    maxItems: maxItems
                )
            }
        }

        public func userPlaylistsPublisher(
            userID: String,
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedPlaylist>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.userPlaylists(userID: userID, limit: limit, offset: offset)
            }
        }

        public func coverImagePublisher(
            id: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SpotifyImage], Error> {
            publisher(priority: priority) { service in
                try await service.coverImage(id: id)
            }
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension PlaylistsService where Capability == UserAuthCapability {

        public func myPlaylistsPublisher(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Page<SimplifiedPlaylist>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority) {
                service, limit, offset in
                try await service.myPlaylists(limit: limit, offset: offset)
            }
        }

        public func allMyPlaylistsPublisher(
            maxItems: Int? = 1000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SimplifiedPlaylist], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allMyPlaylists(maxItems: maxItems)
            }
        }

        public func createPublisher(
            for userID: String,
            name: String,
            isPublic: Bool? = nil,
            collaborative: Bool? = nil,
            description: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Playlist, Error> {
            publisher(priority: priority) { service in
                try await service.create(
                    for: userID,
                    name: name,
                    isPublic: isPublic,
                    collaborative: collaborative,
                    description: description
                )
            }
        }

        public func changeDetailsPublisher(
            id: String,
            name: String? = nil,
            isPublic: Bool? = nil,
            collaborative: Bool? = nil,
            description: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.changeDetails(
                    id: id,
                    name: name,
                    isPublic: isPublic,
                    collaborative: collaborative,
                    description: description
                )
            }
        }

        public func addPublisher(
            to id: String,
            uris: [String],
            position: Int? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.add(to: id, uris: uris, position: position)
            }
        }

        public func removePublisher(
            from id: String,
            uris: [String],
            snapshotId: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.remove(from: id, uris: uris, snapshotId: snapshotId)
            }
        }

        public func removePublisher(
            from id: String,
            positions: [Int],
            snapshotId: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.remove(from: id, positions: positions, snapshotId: snapshotId)
            }
        }

        public func reorderPublisher(
            id: String,
            rangeStart: Int,
            insertBefore: Int,
            rangeLength: Int? = nil,
            snapshotId: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.reorder(
                    id: id,
                    rangeStart: rangeStart,
                    insertBefore: insertBefore,
                    rangeLength: rangeLength,
                    snapshotId: snapshotId
                )
            }
        }

        public func replaceItemsPublisher(
            in id: String,
            with uris: [String],
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.replace(itemsIn: id, with: uris)
            }
        }

        public func uploadCoverImagePublisher(
            for id: String,
            jpegData: Data,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.uploadCoverImage(for: id, jpegData: jpegData)
            }
        }

        public func followPublisher(
            _ id: String,
            isPublic: Bool = true,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.follow(id, isPublic: isPublic)
            }
        }

        public func unfollowPublisher(
            _ id: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.unfollow(id)
            }
        }
    }

#endif

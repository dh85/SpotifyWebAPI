#if canImport(Combine)
    import Combine
    import Foundation

    /// Combine publishers that mirror ``PlaylistsService`` async APIs.
    ///
    /// ## Async Counterparts
    /// When you need async/await, call helpers such as ``PlaylistsService/get(_:market:fields:additionalTypes:)``
    /// or ``PlaylistsService/items(_:market:fields:limit:offset:additionalTypes:)``—the publishers inside this
    /// file just wrap those implementations.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension PlaylistsService where Capability: PublicSpotifyCapability {

        /// Get a playlist owned by a Spotify user.
        /// Corresponds to: `GET /v1/playlists/{id}`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - fields: A comma-separated list of fields to filter the response.
        ///   - additionalTypes: A set of item types to include (track, episode).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a full `Playlist` object.
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

        /// Get the tracks or episodes in a playlist.
        /// Corresponds to: `GET /v1/playlists/{id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - fields: A comma-separated list of fields to filter the response.
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - additionalTypes: A set of item types to include (track, episode).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a `Page` object containing `PlaylistTrackItem` items.
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

        /// Get all tracks or episodes in a playlist.
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - market: An ISO 3166-1 alpha-2 country code.
        ///   - fields: A comma-separated list of fields to filter the response.
        ///   - additionalTypes: A set of item types to include (track, episode).
        ///   - maxItems: Limit on total items to fetch. Default: 5,000. Use `nil` for unlimited.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of all `PlaylistTrackItem` objects.
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

        /// Get a list of the playlists owned or followed by a specific user.
        /// Corresponds to: `GET /v1/users/{user_id}/playlists`
        ///
        /// - Parameters:
        ///   - userID: The Spotify user ID.
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a `Page` of `SimplifiedPlaylist` objects.
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

        /// Get the cover image for a playlist.
        /// Corresponds to: `GET /v1/playlists/{id}/images`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a list of `SpotifyImage` objects.
        public func coverImagePublisher(
            id: String,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SpotifyImage], Error> {
            makePublisher(id, priority: priority, operation: Self.coverImage)
        }
    }

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension PlaylistsService where Capability == UserAuthCapability {

        /// Get a list of the playlists owned or followed by the current Spotify user.
        /// Corresponds to: `GET /v1/me/playlists`
        ///
        /// - Parameters:
        ///   - limit: The number of items to return (1-50). Default: 20.
        ///   - offset: The index of the first item to return. Default: 0.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits a `Page` of `SimplifiedPlaylist` objects.
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

        /// Get all playlists owned or followed by the current user.
        /// This is a convenience method that fetches in chunks and concatenates results.
        ///
        /// - Parameters:
        ///   - maxItems: Maximum number of playlists to return. Default is 1000.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits an array of `SimplifiedPlaylist` objects.
        public func allMyPlaylistsPublisher(
            maxItems: Int? = 1000,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<[SimplifiedPlaylist], Error> {
            libraryAllItemsPublisher(maxItems: maxItems, priority: priority) { service, maxItems in
                try await service.allMyPlaylists(maxItems: maxItems)
            }
        }

        /// Create a new playlist.
        /// Corresponds to: `POST /v1/users/{user_id}/playlists`
        ///
        /// - Parameters:
        ///   - userID: The Spotify user ID.
        ///   - name: The name of the playlist.
        ///   - isPublic: Whether the playlist is public.
        ///   - collaborative: Whether the playlist is collaborative.
        ///   - description: A description for the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the created `Playlist` object.
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

        /// Change playlist details.
        /// Corresponds to: `PUT /v1/playlists/{id}`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - name: The new name for the playlist.
        ///   - isPublic: Whether the playlist should be public.
        ///   - collaborative: Whether the playlist should be collaborative.
        ///   - description: A new description for the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when the operation is complete.
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

        /// Add items to a playlist.
        /// Corresponds to: `POST /v1/playlists/{playlist_id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - uris: An array of Spotify URIs to add.
        ///   - position: The position to insert the items at.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the snapshot ID of the playlist.
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

        /// Remove items from a playlist.
        /// Corresponds to: `DELETE /v1/playlists/{playlist_id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - uris: An array of Spotify URIs to remove.
        ///   - snapshotID: The snapshot ID of the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the snapshot ID of the playlist.
        public func removePublisher(
            from id: String,
            uris: [String],
            snapshotID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.remove(from: id, uris: uris, snapshotId: snapshotID)
            }
        }

        /// Remove specific occurrences of items from a playlist.
        /// Corresponds to: `DELETE /v1/playlists/{playlist_id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - items: An array of `URIWithPositions` to remove.
        ///   - snapshotID: The snapshot ID of the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the snapshot ID of the playlist.
        public func removePublisher(
            from id: String,
            items: [URIWithPositions],
            snapshotID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.remove(from: id, items: items, snapshotId: snapshotID)
            }
        }

        /// Reorder items in a playlist.
        /// Corresponds to: `PUT /v1/playlists/{playlist_id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - rangeStart: The position of the first item to be reordered.
        ///   - insertBefore: The position where the items should be inserted.
        ///   - rangeLength: The amount of items to be reordered.
        ///   - snapshotID: The snapshot ID of the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the snapshot ID of the playlist.
        public func reorderPublisher(
            in id: String,
            rangeStart: Int,
            insertBefore: Int,
            rangeLength: Int = 1,
            snapshotID: String? = nil,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.reorder(
                    id: id,
                    rangeStart: rangeStart,
                    insertBefore: insertBefore,
                    rangeLength: rangeLength,
                    snapshotId: snapshotID
                )
            }
        }

        /// Replace all items in a playlist.
        /// Corresponds to: `PUT /v1/playlists/{playlist_id}/tracks`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - uris: An array of Spotify URIs to set.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits the snapshot ID of the playlist.
        public func replacePublisher(
            in id: String,
            with uris: [String],
            priority: TaskPriority? = nil
        ) -> AnyPublisher<String, Error> {
            publisher(priority: priority) { service in
                try await service.replace(itemsIn: id, with: uris)
            }
        }

        /// Upload a custom playlist cover image.
        /// Corresponds to: `PUT /v1/playlists/{playlist_id}/images`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - imageData: The image data (JPEG, max 256KB).
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when successful.
        public func uploadCoverImagePublisher(
            for id: String,
            imageData: Data,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.uploadCoverImage(for: id, imageData: imageData)
            }
        }

        /// Follow a playlist.
        /// Corresponds to: `POST /v1/playlists/{id}/followers`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - isPublic: Whether the playlist should be public.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when the operation is complete.
        public func followPublisher(
            _ id: String,
            isPublic: Bool = true,
            priority: TaskPriority? = nil
        ) -> AnyPublisher<Void, Error> {
            publisher(priority: priority) { service in
                try await service.follow(id, isPublic: isPublic)
            }
        }

        /// Unfollow a playlist.
        /// Corresponds to: `DELETE /v1/playlists/{id}/followers`
        ///
        /// - Parameters:
        ///   - id: The Spotify ID for the playlist.
        ///   - priority: The priority of the task.
        /// - Returns: A publisher that emits `Void` when the operation is complete.
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

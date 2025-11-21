import Foundation

#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SpotifyClient {
    
    /// Convert any async method to a Combine publisher.
    public func publisher<T>(
        for operation: @escaping () async throws -> T
    ) -> AnyPublisher<T, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await operation()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Albums Service

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension AlbumsService where Capability: PublicSpotifyCapability {
    
    /// Get album as Combine publisher.
    public func getPublisher(_ id: String, market: String? = nil) -> AnyPublisher<Album, Error> {
        client.publisher { try await self.get(id, market: market) }
    }
    
    /// Get multiple albums as Combine publisher.
    public func severalPublisher(ids: Set<String>, market: String? = nil) -> AnyPublisher<[Album], Error> {
        client.publisher { try await self.several(ids: ids, market: market) }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension AlbumsService where Capability == UserAuthCapability {
    
    /// Get saved albums as Combine publisher.
    public func savedPublisher(limit: Int = 20, offset: Int = 0) -> AnyPublisher<Page<SavedAlbum>, Error> {
        client.publisher { try await self.saved(limit: limit, offset: offset) }
    }
    
    /// Save albums as Combine publisher.
    public func savePublisher(_ ids: Set<String>) -> AnyPublisher<Void, Error> {
        client.publisher { try await self.save(ids) }
    }
}

// MARK: - Search Service

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SearchService where Capability: PublicSpotifyCapability {
    
    /// Search as Combine publisher.
    public func executePublisher(
        query: String,
        types: Set<SearchType>,
        market: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) -> AnyPublisher<SearchResults, Error> {
        client.publisher { 
            try await self.execute(
                query: query, 
                types: types, 
                market: market, 
                limit: limit, 
                offset: offset
            ) 
        }
    }
}

// MARK: - Playlists Service

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension PlaylistsService where Capability: PublicSpotifyCapability {
    
    /// Get playlist as Combine publisher.
    public func getPublisher(_ id: String, market: String? = nil) -> AnyPublisher<Playlist, Error> {
        client.publisher { try await self.get(id, market: market) }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension PlaylistsService where Capability == UserAuthCapability {
    
    /// Get user playlists as Combine publisher.
    public func myPlaylistsPublisher(limit: Int = 20, offset: Int = 0) -> AnyPublisher<Page<SimplifiedPlaylist>, Error> {
        client.publisher { try await self.myPlaylists(limit: limit, offset: offset) }
    }
    
    /// Create playlist as Combine publisher.
    public func createPublisher(
        for userID: String,
        name: String,
        isPublic: Bool? = nil,
        collaborative: Bool? = nil,
        description: String? = nil
    ) -> AnyPublisher<Playlist, Error> {
        client.publisher { 
            try await self.create(
                for: userID, 
                name: name, 
                isPublic: isPublic, 
                collaborative: collaborative, 
                description: description
            ) 
        }
    }
}

// MARK: - Users Service

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension UsersService where Capability == UserAuthCapability {
    
    /// Get current user profile as Combine publisher.
    public func mePublisher() -> AnyPublisher<CurrentUserProfile, Error> {
        client.publisher { try await self.me() }
    }
}

#endif
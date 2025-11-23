#if canImport(Combine)
    import Combine
    import Foundation

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    protocol SpotifyCombineService: Sendable {
        associatedtype Capability: Sendable
        var client: SpotifyClient<Capability> { get }
    }

    extension AlbumsService: SpotifyCombineService {}
    extension ArtistsService: SpotifyCombineService {}
    extension AudiobooksService: SpotifyCombineService {}
    extension BrowseService: SpotifyCombineService {}
    extension ChaptersService: SpotifyCombineService {}
    extension EpisodesService: SpotifyCombineService {}
    extension PlayerService: SpotifyCombineService {}
    extension PlaylistsService: SpotifyCombineService {}
    extension SearchService: SpotifyCombineService {}
    extension ShowsService: SpotifyCombineService {}
    extension TracksService: SpotifyCombineService {}
    extension UsersService: SpotifyCombineService {}

    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    extension SpotifyCombineService {

        func publisher<Output: Sendable>(
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            client.makePublisher(priority: priority) {
                try await operation(self)
            }
        }

        func pagedPublisher<PageType: Sendable>(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, Int, Int) async throws -> PageType
        ) -> AnyPublisher<PageType, Error> {
            publisher(priority: priority) { service in
                try await operation(service, limit, offset)
            }
        }

        func catalogItemPublisher<ID: Sendable, Output: Sendable>(
            id: ID,
            market: String? = nil,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, ID, String?) async throws -> Output
        ) -> AnyPublisher<Output, Error> {
            publisher(priority: priority) { service in
                try await operation(service, id, market)
            }
        }

        func catalogCollectionPublisher<IDCollection, Output: Sendable>(
            ids: IDCollection,
            market: String? = nil,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, IDCollection, String?) async throws -> Output
        ) -> AnyPublisher<Output, Error> where IDCollection: Collection & Sendable {
            publisher(priority: priority) { service in
                try await operation(service, ids, market)
            }
        }

        func librarySavedPublisher<Item: Sendable>(
            limit: Int = 20,
            offset: Int = 0,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, Int, Int) async throws -> Page<Item>
        ) -> AnyPublisher<Page<Item>, Error> {
            pagedPublisher(limit: limit, offset: offset, priority: priority, operation: operation)
        }

        func libraryAllItemsPublisher<Item: Sendable>(
            maxItems: Int? = nil,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, Int?) async throws -> [Item]
        ) -> AnyPublisher<[Item], Error> {
            publisher(priority: priority) { service in
                try await operation(service, maxItems)
            }
        }

        func libraryMutationPublisher<Result: Sendable>(
            ids: Set<String>,
            priority: TaskPriority? = nil,
            operation: @escaping @Sendable (Self, Set<String>) async throws -> Result
        ) -> AnyPublisher<Result, Error> {
            publisher(priority: priority) { service in
                try await operation(service, ids)
            }
        }
    }

#endif

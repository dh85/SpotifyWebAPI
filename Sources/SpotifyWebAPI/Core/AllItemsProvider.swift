import Foundation

/// Provides a unified interface for fetching or streaming every item from a paginated endpoint.
struct AllItemsProvider<Capability: Sendable, Item: Codable & Sendable & Equatable>: Sendable {
    private let client: SpotifyClient<Capability>
    private let pageSize: Int
    private let defaultMaxItems: Int?
    private let fetchPage: @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<Item>

    init(
        client: SpotifyClient<Capability>,
        pageSize: Int,
        defaultMaxItems: Int?,
        fetchPage: @escaping (@Sendable (_ limit: Int, _ offset: Int) async throws -> Page<Item>)
    ) {
        self.client = client
        self.pageSize = pageSize
        self.defaultMaxItems = defaultMaxItems
        self.fetchPage = fetchPage
    }

    private func resolvedMaxItems(_ override: Int?) -> Int? {
        override ?? defaultMaxItems
    }

    /// Fetches and accumulates all pages.
    func all(maxItems: Int? = nil) async throws -> [Item] {
        try await client.collectAllPages(
            pageSize: pageSize,
            maxItems: resolvedMaxItems(maxItems),
            fetchPage: fetchPage
        )
    }

    /// Streams items one-by-one, fetching pages lazily.
    func stream(maxItems: Int? = nil) -> AsyncThrowingStream<Item, Error> {
        client.streamItems(
            pageSize: pageSize,
            maxItems: resolvedMaxItems(maxItems),
            fetchPage: fetchPage
        )
    }
}

extension SpotifyClient {
    /// Creates a reusable provider for fetching/streaming all items from a paginated endpoint.
    nonisolated func makeAllItemsProvider<Item: Codable & Sendable & Equatable>(
        pageSize: Int = 50,
        defaultMaxItems: Int? = nil,
        fetchPage: @escaping (@Sendable (_ limit: Int, _ offset: Int) async throws -> Page<Item>)
    ) -> AllItemsProvider<Capability, Item> {
        AllItemsProvider(
            client: self,
            pageSize: pageSize,
            defaultMaxItems: defaultMaxItems,
            fetchPage: fetchPage
        )
    }
}

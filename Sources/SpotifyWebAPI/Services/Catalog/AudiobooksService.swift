import Foundation

private struct SeveralAudiobooksWrapper: Decodable {
    let audiobooks: [Audiobook?]
}

/// A service for fetching and managing Spotify Audiobook resources and their chapters.
public struct AudiobooksService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Public Access
extension AudiobooksService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single audiobook.
    ///
    /// Corresponds to: `GET /v1/audiobooks/{id}`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the audiobook.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full ``Audiobook`` object.
    public func get(_ id: String, market: String? = nil) async throws
        -> Audiobook
    {
        let query: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let request = SpotifyRequest<Audiobook>.get(
            "/audiobooks/\(id)",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several audiobooks.
    ///
    /// Corresponds to: `GET /v1/audiobooks`.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the audiobooks (max 50).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full ``Audiobook`` objects.
    public func several(ids: Set<String>, market: String? = nil) async throws
        -> [Audiobook?]
    {
        let sortedIds = ids.sorted()
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [.init(name: "ids", value: sortedIds.joined(separator: ","))]
            + marketQuery

        let request = SpotifyRequest<SeveralAudiobooksWrapper>.get(
            "/audiobooks",
            query: query
        )
        return try await client.perform(request).audiobooks
    }

    /// Get chapters for a specific audiobook.
    ///
    /// Corresponds to: `GET /v1/audiobooks/{id}/chapters`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the audiobook.
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A paginated list of ``SimplifiedChapter`` items.
    public func chapters(
        for id: String,
        limit: Int = 20,
        offset: Int = 0,
        market: String? = nil
    ) async throws -> Page<SimplifiedChapter> {
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [
                .init(name: "limit", value: String(limit)),
                .init(name: "offset", value: String(offset)),
            ] + marketQuery

        let request = SpotifyRequest<Page<SimplifiedChapter>>.get(
            "/audiobooks/\(id)/chapters",
            query: query
        )
        return try await client.perform(request)
    }
}

// MARK: - User Access
extension AudiobooksService where Capability == UserAuthCapability {

    /// Get a list of the audiobooks saved in the current user's library.
    ///
    /// Corresponds to: `GET /v1/me/audiobooks`.
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameters:
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``SavedAudiobook`` items.
    public func saved(limit: Int = 20, offset: Int = 0) async throws -> Page<
        SavedAudiobook
    > {
        let query: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]
        let request = SpotifyRequest<Page<SavedAudiobook>>.get(
            "/me/audiobooks",
            query: query
        )
        return try await client.perform(request)
    }

    /// Save one or more audiobooks to the current user's library.
    ///
    /// Corresponds to: `PUT /v1/me/audiobooks`.
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the audiobooks (max 50).
    public func save(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.put(
            "/me/audiobooks",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Remove one or more audiobooks from the current user's library.
    ///
    /// Corresponds to: `DELETE /v1/me/audiobooks`.
    /// Requires the `user-library-modify` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the audiobooks (max 50).
    public func remove(_ ids: Set<String>) async throws {
        let request = SpotifyRequest<EmptyResponse>.delete(
            "/me/audiobooks",
            body: IDsBody(ids: ids)
        )
        try await client.perform(request)
    }

    /// Check if one or more audiobooks are already saved in the current user's library.
    ///
    /// Corresponds to: `GET /v1/me/audiobooks/contains`.
    /// Requires the `user-library-read` scope.
    ///
    /// - Parameter ids: A list of the Spotify IDs for the audiobooks (max 50).
    /// - Returns: An array of booleans corresponding to the IDs requested.
    public func checkSaved(_ ids: Set<String>) async throws -> [Bool] {
        let sortedIds = ids.sorted()
        let query = [
            URLQueryItem(name: "ids", value: sortedIds.joined(separator: ","))
        ]
        let request = SpotifyRequest<[Bool]>.get(
            "/me/audiobooks/contains",
            query: query
        )
        return try await client.perform(request)
    }
}

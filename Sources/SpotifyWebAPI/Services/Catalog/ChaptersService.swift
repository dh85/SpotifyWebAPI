import Foundation

private struct SeveralChaptersWrapper: Decodable { let chapters: [Chapter] }

/// A service for fetching Spotify Chapter resources.
///
/// Chapters are individual components of an audiobook.
public struct ChaptersService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

extension ChaptersService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single chapter.
    ///
    /// Corresponds to: `GET /v1/chapters/{id}`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the chapter.
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full ``Chapter`` object.
    public func get(_ id: String, market: String? = nil) async throws -> Chapter
    {
        let query: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let request = SpotifyRequest<Chapter>.get(
            "/chapters/\(id)",
            query: query
        )
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several chapters.
    ///
    /// Corresponds to: `GET /v1/chapters`.
    ///
    /// - Parameters:
    ///   - ids: A list of the Spotify IDs for the chapters (max 50).
    ///   - market: Optional. An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of full ``Chapter`` objects.
    public func several(ids: [String], market: String? = nil) async throws
        -> [Chapter]
    {
        let marketQuery: [URLQueryItem] =
            market.map { [.init(name: "market", value: $0)] } ?? []
        let query: [URLQueryItem] =
            [.init(name: "ids", value: ids.joined(separator: ","))]
            + marketQuery

        let request = SpotifyRequest<SeveralChaptersWrapper>.get(
            "/chapters",
            query: query
        )
        return try await client.perform(request).chapters
    }
}

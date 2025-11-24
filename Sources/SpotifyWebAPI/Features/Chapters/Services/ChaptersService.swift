import Foundation

private typealias SeveralChaptersWrapper = ArrayWrapper<Chapter>

/// A service for fetching Spotify Chapter resources.
///
/// Chapters are individual components of an audiobook.
public struct ChaptersService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Helpers
extension ChaptersService: ServiceIDValidating {
    static var maxBatchSize: Int { SpotifyAPILimits.Chapters.batchSize }

    private func validateChapterIDs(_ ids: [String]) throws {
        try validateIDs(ids)
    }
}

// MARK: - Public Access
extension ChaptersService where Capability: PublicSpotifyCapability {

    /// Get Spotify catalog information for a single chapter.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the chapter.
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A full `Chapter` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-chapter)
    public func get(_ id: String, market: String? = nil) async throws -> Chapter {
        let query = makeMarketQueryItems(from: market)
        let request = SpotifyRequest<Chapter>.get("/chapters/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get Spotify catalog information for several chapters identified by their Spotify IDs.
    ///
    /// - Parameters:
    ///   - ids: A list of Spotify IDs (max 50).
    ///   - market: An ISO 3166-1 alpha-2 country code.
    /// - Returns: A list of `Chapter` objects.
    /// - Throws: `SpotifyError` if the request fails or ID limit is exceeded.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-several-chapters)
    public func several(ids: [String], market: String? = nil) async throws -> [Chapter] {
        try validateChapterIDs(ids)
        let query =
            [URLQueryItem(name: "ids", value: ids.joined(separator: ","))]
            + makeMarketQueryItems(from: market)
        let request = SpotifyRequest<SeveralChaptersWrapper>.get("/chapters", query: query)
        return try await client.perform(request).items
    }
}

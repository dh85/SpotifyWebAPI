import Foundation

private struct NewReleasesResponse: Decodable {
    let albums: Page<SimplifiedAlbum>
}

private struct AvailableMarketsResponse: Decodable {
    let markets: [String]
}

private struct SeveralCategoriesResponse: Decodable {
    let categories: Page<SpotifyCategory>
}

/// A service for accessing Spotify's public browsing features, such as New Releases, Categories, and Market availability.
public struct BrowseService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Public Access
extension BrowseService where Capability: PublicSpotifyCapability {

    /// Get a list of new album releases featured in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/new-releases`.
    ///
    /// - Parameters:
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of albums to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``SimplifiedAlbum`` items.
    public func newReleases(
        country: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {

        let clampedLimit = min(max(limit, 1), 50)

        var queryItems: [URLQueryItem] = [
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]
        if let country {
            queryItems.append(.init(name: "country", value: country))
        }

        let request = SpotifyRequest<NewReleasesResponse>.get(
            "/browse/new-releases",
            query: queryItems
        )
        return try await client.perform(request).albums
    }

    /// Get a single category used to tag content in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/categories/{id}`.
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the category.
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - locale: Optional. The desired language, e.g., "es_MX".
    /// - Returns: A single ``Category`` object.
    public func category(
        id: String,
        country: String? = nil,
        locale: String? = nil
    ) async throws -> SpotifyCategory {

        var queryItems: [URLQueryItem] = []
        if let country {
            queryItems.append(.init(name: "country", value: country))
        }
        if let locale {
            queryItems.append(.init(name: "locale", value: locale))
        }

        let request = SpotifyRequest<SpotifyCategory>.get(
            "/browse/categories/\(id)",
            query: queryItems
        )
        return try await client.perform(request)
    }

    /// Get a list of categories used to tag content in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/categories`.
    ///
    /// - Parameters:
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - locale: Optional. The desired language, e.g., "es_MX".
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``Category`` items.
    public func categories(
        country: String? = nil,
        locale: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SpotifyCategory> {

        let clampedLimit = min(max(limit, 1), 50)

        var queryItems: [URLQueryItem] = [
            .init(name: "limit", value: String(clampedLimit)),
            .init(name: "offset", value: String(offset)),
        ]
        if let country {
            queryItems.append(.init(name: "country", value: country))
        }
        if let locale {
            queryItems.append(.init(name: "locale", value: locale))
        }

        let request = SpotifyRequest<SeveralCategoriesResponse>.get(
            "/browse/categories",
            query: queryItems
        )
        return try await client.perform(request).categories
    }

    /// Get the list of markets (countries) where Spotify is available.
    ///
    /// Corresponds to: `GET /v1/markets`.
    ///
    /// - Returns: A list of ISO 3166-1 alpha-2 country codes.
    public func availableMarkets() async throws -> [String] {
        let request = SpotifyRequest<AvailableMarketsResponse>.get("/markets")
        return try await client.perform(request).markets
    }
}

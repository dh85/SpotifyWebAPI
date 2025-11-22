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
///
/// ## Overview
///
/// BrowseService provides access to:
/// - New album releases
/// - Browse categories
/// - Available markets (countries)
///
/// ## Examples
///
/// ### Get New Releases
/// ```swift
/// let newReleases = try await client.browse.newReleases(
///     country: "US",
///     limit: 20
/// )
///
/// print("New releases:")
/// for album in newReleases.items {
///     print("\(album.name) by \(album.artistNames)")
/// }
/// ```
///
/// ### Browse Categories
/// ```swift
/// // Get all categories
/// let categories = try await client.browse.categories(
///     country: "US",
///     limit: 50
/// )
///
/// for category in categories.items {
///     print("\(category.name): \(category.id)")
/// }
///
/// // Get specific category
/// let category = try await client.browse.category(
///     id: "toplists",
///     country: "US"
/// )
/// print("\(category.name): \(category.description ?? "No description")")
/// ```
///
/// ### Get Available Markets
/// ```swift
/// let markets = try await client.browse.availableMarkets()
/// print("Spotify is available in \(markets.count) markets")
/// print("Markets: \(markets.joined(separator: ", "))")
/// ```
///
/// ### Localized Content
/// ```swift
/// // Get categories in Spanish (Mexico)
/// let categories = try await client.browse.categories(
///     country: "MX",
///     locale: "es_MX",
///     limit: 20
/// )
/// ```
public struct BrowseService<Capability: Sendable>: Sendable {
    let client: SpotifyClient<Capability>
    init(client: SpotifyClient<Capability>) { self.client = client }
}

// MARK: - Public Access

extension BrowseService where Capability: PublicSpotifyCapability {

    /// Get a list of new album releases featured in Spotify.
    /// Corresponds to: `GET /v1/browse/new-releases`
    ///
    /// - Parameters:
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - limit: The number of albums to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``SimplifiedAlbum`` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-new-releases)
    public func newReleases(
        country: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SimplifiedAlbum> {
        let query = try QueryBuilder()
            .addingPagination(limit: limit, offset: offset)
            .addingCountry(country)
            .build()

        let request = SpotifyRequest<NewReleasesResponse>.get("/browse/new-releases", query: query)
        return try await client.perform(request).albums
    }

    /// Get a single category used to tag content in Spotify.
    /// Corresponds to: `GET /v1/browse/categories/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the category.
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - locale: The desired language, e.g., "es_MX".
    /// - Returns: A single ``SpotifyCategory`` object.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-category)
    public func category(
        id: String,
        country: String? = nil,
        locale: String? = nil
    ) async throws -> SpotifyCategory {
        let query = QueryBuilder()
            .addingCountry(country)
            .addingLocale(locale)
            .build()
        let request = SpotifyRequest<SpotifyCategory>.get("/browse/categories/\(id)", query: query)
        return try await client.perform(request)
    }

    /// Get a list of categories used to tag content in Spotify.
    /// Corresponds to: `GET /v1/browse/categories`
    ///
    /// - Parameters:
    ///   - country: An ISO 3166-1 alpha-2 country code.
    ///   - locale: The desired language, e.g., "es_MX".
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A paginated list of ``SpotifyCategory`` items.
    /// - Throws: `SpotifyError` if the request fails or limit is out of bounds.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-categories)
    public func categories(
        country: String? = nil,
        locale: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<SpotifyCategory> {
        let query = try QueryBuilder()
            .addingPagination(limit: limit, offset: offset)
            .addingCountry(country)
            .addingLocale(locale)
            .build()

        let request = SpotifyRequest<SeveralCategoriesResponse>.get("/browse/categories", query: query)
        return try await client.perform(request).categories
    }

    /// Get the list of markets (countries) where Spotify is available.
    /// Corresponds to: `GET /v1/markets`
    ///
    /// - Returns: A list of ISO 3166-1 alpha-2 country codes.
    /// - Throws: `SpotifyError` if the request fails.
    ///
    /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-available-markets)
    public func availableMarkets() async throws -> [String] {
        let request = SpotifyRequest<AvailableMarketsResponse>.get("/markets")
        return try await client.perform(request).markets
    }
}

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
///
/// ## Combine Counterparts
///
/// Matching publishers such as ``BrowseService/newReleasesPublisher(country:limit:offset:priority:)``
/// and ``BrowseService/categoriesPublisher(country:locale:limit:offset:priority:)`` live in
/// `BrowseService+Combine.swift`. Import Combine to expose them; they call back into the async
/// APIs so pagination, validation, and instrumentation stay in sync.
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
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-new-releases)
  public func newReleases(
    country: String? = nil,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> Page<SimplifiedAlbum> {
    try validateLimit(limit)
    let response =
      try await client
      .get("/browse/new-releases")
      .paginate(limit: limit, offset: offset)
      .query("country", country)
      .decode(NewReleasesResponse.self)
    return response.albums
  }

  /// Streams Spotify's new releases a page at a time.
  ///
  /// - Parameters:
  ///   - country: Optional market filter for regional listings.
  ///   - pageSize: Number of albums to request per page (clamped to 1...50). Default: 50.
  ///   - maxPages: Optional limit on total pages fetched.
  /// - Returns: Async sequence yielding `Page<SimplifiedAlbum>` results straight from the API.
  public func streamNewReleasePages(
    country: String? = nil,
    pageSize: Int = 50,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SimplifiedAlbum>, Error> {
    client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
      try await self.newReleases(country: country, limit: limit, offset: offset)
    }
  }

  /// Streams Spotify's new releases item-by-item for lightweight processing.
  public func streamNewReleases(
    country: String? = nil,
    pageSize: Int = 50,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SimplifiedAlbum, Error> {
    client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
      try await self.newReleases(country: country, limit: limit, offset: offset)
    }
  }

  /// Get a single category used to tag content in Spotify.
  /// Corresponds to: `GET /v1/browse/categories/{id}`
  ///
  /// - Parameters:
  ///   - id: The Spotify ID for the category.
  ///   - country: An ISO 3166-1 alpha-2 country code.
  ///   - locale: The desired language, e.g., "es_MX".
  /// - Returns: A single ``SpotifyCategory`` object.
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-a-category)
  public func category(
    id: String,
    country: String? = nil,
    locale: String? = nil
  ) async throws -> SpotifyCategory {
    return
      try await client
      .get("/browse/categories/\(id)")
      .query("country", country)
      .query("locale", locale)
      .decode(SpotifyCategory.self)
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
  /// - Throws: `SpotifyClientError` if the request fails or limit is out of bounds.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-categories)
  public func categories(
    country: String? = nil,
    locale: String? = nil,
    limit: Int = 20,
    offset: Int = 0
  ) async throws -> Page<SpotifyCategory> {
    try validateLimit(limit)
    let response =
      try await client
      .get("/browse/categories")
      .paginate(limit: limit, offset: offset)
      .query("country", country)
      .query("locale", locale)
      .decode(SeveralCategoriesResponse.self)
    return response.categories
  }

  /// Streams Spotify browse categories for infinite-scroll style UIs.
  ///
  /// - Parameters:
  ///   - country: Optional market filter.
  ///   - locale: Optional locale (e.g., "es_MX").
  ///   - pageSize: Desired number of categories per request (clamped to 1...50). Default: 50.
  ///   - maxPages: Optional cap on emitted pages.
  public func streamCategoryPages(
    country: String? = nil,
    locale: String? = nil,
    pageSize: Int = 50,
    maxPages: Int? = nil
  ) -> AsyncThrowingStream<Page<SpotifyCategory>, Error> {
    client.streamPages(pageSize: pageSize, maxPages: maxPages) { limit, offset in
      try await self.categories(
        country: country,
        locale: locale,
        limit: limit,
        offset: offset
      )
    }
  }

  /// Streams Spotify browse categories individually, ideal for incremental UI updates.
  public func streamCategories(
    country: String? = nil,
    locale: String? = nil,
    pageSize: Int = 50,
    maxItems: Int? = nil
  ) -> AsyncThrowingStream<SpotifyCategory, Error> {
    client.streamItems(pageSize: pageSize, maxItems: maxItems) { limit, offset in
      try await self.categories(
        country: country,
        locale: locale,
        limit: limit,
        offset: offset
      )
    }
  }

  /// Get the list of markets (countries) where Spotify is available.
  /// Corresponds to: `GET /v1/markets`
  ///
  /// - Returns: A list of ISO 3166-1 alpha-2 country codes.
  /// - Throws: `SpotifyClientError` if the request fails.
  ///
  /// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-available-markets)
  public func availableMarkets() async throws -> [String] {
    let response =
      try await client
      .get("/markets")
      .decode(AvailableMarketsResponse.self)
    return response.markets
  }
}

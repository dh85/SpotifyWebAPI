import Foundation

extension SpotifyClient where Capability: PublicSpotifyCapability {
    /// Get a list of categories used to tag content in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/categories`
    ///
    /// - Parameters:
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - locale: Optional. The desired language, e.g., "es_MX".
    ///   - limit: The number of items to return (1-50). Default: 20.
    ///   - offset: The index of the first item to return. Default: 0.
    /// - Returns: A `Page` object containing `Category` items.
    public func categories(
        country: String? = nil,
        locale: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> Page<Category> {

        // Clamp limit to Spotify's allowed range (1-50)
        let clampedLimit = min(max(limit, 1), 50)

        let endpoint = CategoriesEndpoint.severalCategories(
            country: country,
            locale: locale,
            limit: clampedLimit,
            offset: offset
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // Decode the wrapper object
        let response = try await requestJSON(
            SeveralCategoriesResponse.self,
            url: url
        )

        // Return the unwrapped page of categories
        return response.categories
    }

    /// Get a single category used to tag content in Spotify.
    ///
    /// Corresponds to: `GET /v1/browse/categories/{id}`
    ///
    /// - Parameters:
    ///   - id: The Spotify ID for the category.
    ///   - country: Optional. An ISO 3166-1 alpha-2 country code.
    ///   - locale: Optional. The desired language, e.g., "es_MX".
    /// - Returns: A single `Category` object.
    public func category(
        id: String,
        country: String? = nil,
        locale: String? = nil
    ) async throws -> Category {

        let endpoint = CategoriesEndpoint.singleCategory(
            id: id,
            country: country,
            locale: locale
        )
        let url = apiURL(path: endpoint.path, queryItems: endpoint.query)

        // This endpoint returns the Category object directly
        return try await requestJSON(Category.self, url: url)
    }
}

import Foundation

/// Wrapper for the `GET /v1/browse/categories` endpoint response.
struct SeveralCategoriesResponse: Codable, Sendable, Equatable {
    let categories: Page<Category>
}

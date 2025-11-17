import Foundation

enum CategoriesEndpoint {
    /// GET /v1/browse/categories
    static func severalCategories(
        country: String?,
        locale: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/browse/categories"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let country {
            items.append(.init(name: "country", value: country))
        }
        if let locale {
            items.append(.init(name: "locale", value: locale))
        }

        return (path, items)
    }

    /// GET /v1/browse/categories/{id}
    static func singleCategory(
        id: String,
        country: String?,
        locale: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/browse/categories/\(encodedID)"

        var items: [URLQueryItem] = []

        if let country {
            items.append(.init(name: "country", value: country))
        }
        if let locale {
            items.append(.init(name: "locale", value: locale))
        }

        return (path, items.isEmpty ? [] : items)
    }
}

import Foundation

enum SearchEndpoint {

    /// GET /v1/search
    static func search(
        query: String,
        types: Set<SearchType>,
        market: String?,
        limit: Int,
        offset: Int,
        includeExternal: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/search"

        var items: [URLQueryItem] = [
            .init(name: "q", value: query),
            .init(name: "type", value: types.spotifyQueryValue),
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }
        if let includeExternal {
            // e.g., "audio"
            items.append(
                .init(name: "include_external", value: includeExternal)
            )
        }

        return (path, items)
    }
}

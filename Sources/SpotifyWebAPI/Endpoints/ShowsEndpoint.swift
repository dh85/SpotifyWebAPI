import Foundation

enum ShowsEndpoint {

    /// GET /v1/shows/{id}
    static func show(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/shows/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/shows
    static func severalShows(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/shows"

        var items: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/shows/{id}/episodes
    static func showEpisodes(
        id: String,
        market: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/shows/\(encodedID)/episodes"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/me/shows
    static func currentUserSavedShows(
        limit: Int,
        offset: Int,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/shows"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// PUT /v1/me/shows
    static func saveShowsForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/shows", query: [])
    }

    /// DELETE /v1/me/shows
    static func removeShowsForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/shows", query: [])
    }

    /// GET /v1/me/shows/contains
    static func checkCurrentUserSavedShows(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/shows/contains"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }
}

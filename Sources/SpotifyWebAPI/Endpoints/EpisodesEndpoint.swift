import Foundation

enum EpisodesEndpoint {

    /// GET /v1/episodes/{id}
    static func episode(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/episodes/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/episodes
    static func severalEpisodes(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/episodes"

        var items: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/me/episodes
    static func currentUserSavedEpisodes(
        market: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/episodes"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// PUT /v1/me/episodes
    static func saveEpisodesForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/episodes", query: [])
    }

    /// DELETE /v1/me/episodes
    static func removeEpisodesForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/episodes", query: [])
    }

    /// GET /v1/me/episodes/contains
    static func checkCurrentUserSavedEpisodes(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/episodes/contains"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }
}

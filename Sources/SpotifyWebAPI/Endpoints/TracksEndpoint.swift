import Foundation

enum TracksEndpoint {

    /// GET /v1/tracks/{id}
    static func track(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/tracks/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/tracks
    static func severalTracks(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/tracks"

        var items: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/me/tracks
    static func currentUserSavedTracks(
        limit: Int,
        offset: Int,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/tracks"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// PUT /v1/me/tracks
    static func saveTracksForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/tracks", query: [])
    }

    /// DELETE /v1/me/tracks
    static func removeTracksForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/tracks", query: [])
    }

    /// GET /v1/me/tracks/contains
    static func checkCurrentUserSavedTracks(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/tracks/contains"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }
}

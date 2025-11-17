import Foundation

enum AlbumsEndpoint {
    /// GET /v1/albums/{id}
    static func album(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/albums/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/albums
    static func severalAlbums(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/albums"

        var items: [URLQueryItem] = [
            // Join the array into a comma-separated string
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/albums/{id}/tracks
    static func albumTracks(
        id: String,
        market: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/albums/\(encodedID)/tracks"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/me/albums
    static func currentUserSavedAlbums(
        limit: Int,
        offset: Int,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/albums"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// PUT /v1/me/albums
    static func saveAlbumsForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        return (path: "/me/albums", query: [])
    }

    /// DELETE /v1/me/albums
    static func removeAlbumsForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body, consistent with the PUT method
        return (path: "/me/albums", query: [])
    }

    /// GET /v1/me/albums/contains
    static func checkCurrentUserSavedAlbums(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/albums/contains"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }

    /// GET /v1/browse/new-releases
    static func newReleases(
        country: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/browse/new-releases"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let country {
            items.append(.init(name: "country", value: country))
        }

        return (path, items)
    }
}

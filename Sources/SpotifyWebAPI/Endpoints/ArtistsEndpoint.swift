import Foundation

enum ArtistsEndpoint {

    /// GET /v1/artists/{id}
    static func artist(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/artists/\(encodedID)"

        return (path, [])
    }

    /// GET /v1/artists
    static func severalArtists(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/artists"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }

    /// GET /v1/artists/{id}/albums
    static func artistAlbums(
        id: String,
        includeGroups: [String]?,
        market: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/artists/\(encodedID)/albums"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let includeGroups, !includeGroups.isEmpty {
            items.append(
                .init(
                    name: "include_groups",
                    value: includeGroups.joined(separator: ",")
                )
            )
        }

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/artists/{id}/top-tracks
    static func artistTopTracks(
        id: String,
        market: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/artists/\(encodedID)/top-tracks"

        let items: [URLQueryItem] = [
            .init(name: "market", value: market)
        ]

        return (path, items)
    }
}

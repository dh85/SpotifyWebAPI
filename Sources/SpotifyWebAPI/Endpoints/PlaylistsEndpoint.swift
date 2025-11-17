import Foundation

enum PlaylistsEndpoint {

    /// GET /v1/playlists/{id}
    static func playlist(
        id: String,
        market: String?,
        fields: String?,
        additionalTypes: [String]?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }
        if let fields {
            items.append(.init(name: "fields", value: fields))
        }
        if let additionalTypes, !additionalTypes.isEmpty {
            items.append(
                .init(
                    name: "additional_types",
                    value: additionalTypes.joined(separator: ",")
                )
            )
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// PUT /v1/playlists/{id}
    static func changePlaylistDetails(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)"

        // Details are sent in the request body
        return (path, [])
    }

    /// GET /v1/playlists/{id}/tracks
    static func playlistItems(
        id: String,
        market: String?,
        fields: String?,
        limit: Int,
        offset: Int,
        additionalTypes: [String]?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/tracks"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }
        if let fields {
            items.append(.init(name: "fields", value: fields))
        }
        if let additionalTypes, !additionalTypes.isEmpty {
            items.append(
                .init(
                    name: "additional_types",
                    value: additionalTypes.joined(separator: ",")
                )
            )
        }

        return (path, items)
    }

    /// PUT /v1/playlists/{id}/tracks (Replace action)
    static func replacePlaylistItems(
        id: String,
        uris: [String]
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/tracks"

        let query: [URLQueryItem] = [
            // The 'replace' action uses a query parameter for URIs
            .init(name: "uris", value: uris.joined(separator: ","))
        ]

        return (path, query)
    }

    /// PUT /v1/playlists/{id}/tracks (Reorder action)
    static func reorderPlaylistItems(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/tracks"

        // The 'reorder' action uses a JSON body, not query parameters
        return (path, [])
    }

    /// POST /v1/playlists/{id}/tracks (Add Items)
    static func addItemsToPlaylist(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/tracks"

        // Parameters (uris, position) are sent in the request body
        return (path, [])
    }

    /// DELETE /v1/playlists/{id}/tracks (Remove Items)
    static func removeItemsFromPlaylist(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/tracks"

        // Parameters are sent in the request body
        return (path, [])
    }

    /// GET /v1/me/playlists
    static func currentUserPlaylists(
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/playlists"

        let items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        return (path, items)
    }

    /// GET /v1/users/{user_id}/playlists
    static func userPlaylists(
        userID: String,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            userID.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? userID
        let path = "/users/\(encodedID)/playlists"

        let items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        return (path, items)
    }

    /// POST /v1/users/{user_id}/playlists (Create Playlist)
    static func createPlaylist(
        userID: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            userID.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? userID
        let path = "/users/\(encodedID)/playlists"

        // Parameters are sent in the request body
        return (path, [])
    }

    /// GET /v1/playlists/{id}/images
    static func playlistCoverImage(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/images"

        // No query parameters
        return (path, [])
    }

    /// PUT /v1/playlists/{id}/images
    static func addCustomPlaylistImage(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/images"

        // Image data is sent in the request body
        return (path, [])
    }
}

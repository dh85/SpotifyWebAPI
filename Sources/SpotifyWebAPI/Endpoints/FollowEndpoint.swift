import Foundation

enum FollowEndpoint {

    /// PUT /v1/playlists/{id}/followers
    static func followPlaylist(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/followers"

        // 'public' status is sent in the request body
        return (path, [])
    }

    /// DELETE /v1/playlists/{id}/followers
    static func unfollowPlaylist(
        id: String
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/playlists/\(encodedID)/followers"

        // No body or query parameters required
        return (path, [])
    }

    /// GET /v1/me/following
    static func getFollowedArtists(
        limit: Int,
        after: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/following"

        var items: [URLQueryItem] = [
            .init(name: "type", value: "artist"),  // Currently only 'artist' is supported
            .init(name: "limit", value: String(limit)),
        ]

        if let after {
            items.append(.init(name: "after", value: after))
        }

        return (path, items)
    }

    /// PUT /v1/me/following
    static func follow(
        type: FollowType
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/following"

        let items: [URLQueryItem] = [
            .init(name: "type", value: type.rawValue)
        ]

        // IDs are sent in the request body
        return (path, items)
    }

    /// DELETE /v1/me/following
    static func unfollow(
        type: FollowType
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/following"

        let items: [URLQueryItem] = [
            .init(name: "type", value: type.rawValue)
        ]

        // IDs are sent in the request body
        return (path, items)
    }

    /// GET /v1/me/following/contains
    static func checkFollowing(
        type: FollowType,
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/following/contains"

        let items: [URLQueryItem] = [
            .init(name: "type", value: type.rawValue),
            .init(name: "ids", value: ids.joined(separator: ",")),
        ]

        return (path, items)
    }

    /// GET /v1/playlists/{id}/followers/contains
    static func checkUsersFollowPlaylist(
        playlistID: String,
        userIDs: [String]
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            playlistID.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? playlistID
        let path = "/playlists/\(encodedID)/followers/contains"

        let items: [URLQueryItem] = [
            .init(name: "ids", value: userIDs.joined(separator: ","))
        ]

        return (path, items)
    }
}

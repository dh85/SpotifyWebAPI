import Foundation

enum UsersEndpoint {

    /// GET /v1/me
    static func currentUserProfile() -> (path: String, query: [URLQueryItem]) {
        // The endpoint is simply "/me" with no query parameters
        return (path: "/me", query: [])
    }

    /// GET /v1/me/top/{type}
    static func topItems(
        type: String,  // "artists" or "tracks"
        timeRange: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/top/\(type)"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let timeRange {
            items.append(.init(name: "time_range", value: timeRange))
        }

        return (path, items)
    }

    /// GET /v1/users/{user_id}
    static func userProfile(id: String) -> (path: String, query: [URLQueryItem])
    {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/users/\(encodedID)"

        return (path, [])
    }
}

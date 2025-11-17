import Foundation

enum AudiobooksEndpoint {

    /// GET /v1/audiobooks/{id}
    static func audiobook(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/audiobooks/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/audiobooks
    static func severalAudiobooks(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/audiobooks"

        var items: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/audiobooks/{id}/chapters
    static func audiobookChapters(
        id: String,
        market: String?,
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/audiobooks/\(encodedID)/chapters"

        var items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }

    /// GET /v1/me/audiobooks
    static func currentUserSavedAudiobooks(
        limit: Int,
        offset: Int
    ) -> (path: String, query: [URLQueryItem]) {

        let path = "/me/audiobooks"

        let items: [URLQueryItem] = [
            .init(name: "limit", value: String(limit)),
            .init(name: "offset", value: String(offset)),
        ]

        return (path, items)
    }

    /// PUT /v1/me/audiobooks
    static func saveAudiobooksForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/audiobooks", query: [])
    }

    /// DELETE /v1/me/audiobooks
    static func removeAudiobooksForCurrentUser() -> (
        path: String, query: [URLQueryItem]
    ) {
        // IDs are sent in the request body
        return (path: "/me/audiobooks", query: [])
    }

    /// GET /v1/me/audiobooks/contains
    static func checkCurrentUserSavedAudiobooks(
        ids: [String]
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/me/audiobooks/contains"
        let query: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]
        return (path, query)
    }

    /// GET /v1/chapters/{id}
    static func chapter(
        id: String,
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {

        let encodedID =
            id.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? id
        let path = "/chapters/\(encodedID)"

        var items: [URLQueryItem] = []
        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items.isEmpty ? [] : items)
    }

    /// GET /v1/chapters
    static func severalChapters(
        ids: [String],
        market: String?
    ) -> (path: String, query: [URLQueryItem]) {
        let path = "/chapters"

        var items: [URLQueryItem] = [
            .init(name: "ids", value: ids.joined(separator: ","))
        ]

        if let market {
            items.append(.init(name: "market", value: market))
        }

        return (path, items)
    }
}

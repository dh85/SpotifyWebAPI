import Foundation

/// Request body for `PUT /v1/playlists/{id}/followers` (Follow Playlist).
struct FollowPlaylistBody: Encodable {
    /// If true, the playlist will be included in the user's public playlists.
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case isPublic = "public"
    }
}

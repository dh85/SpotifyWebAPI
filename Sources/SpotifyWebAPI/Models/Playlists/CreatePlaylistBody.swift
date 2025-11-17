import Foundation

/// Request body for `POST /v1/users/{user_id}/playlists` (Create Playlist).
struct CreatePlaylistBody: Encodable {
    /// The name for the new playlist.
    let name: String

    /// `true` for public, `false` for private.
    let isPublic: Bool?

    /// `true` to make collaborative.
    let collaborative: Bool?

    /// The description for the playlist.
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case isPublic = "public"
        case collaborative
        case description
    }
}

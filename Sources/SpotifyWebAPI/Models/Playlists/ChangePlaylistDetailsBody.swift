import Foundation

/// Request body for `PUT /v1/playlists/{id}` (Change Playlist Details).
struct ChangePlaylistDetailsBody: Encodable {
    let name: String?
    let isPublic: Bool?
    let collaborative: Bool?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case isPublic = "public"
        case collaborative
        case description
    }
}

import Foundation

/// Full playlist model returned by:
/// GET /v1/playlists/{playlist_id}
public struct Playlist: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let href: URL
    public let uri: String

    public let collaborative: Bool
    public let description: String?
    public let externalUrls: SpotifyExternalUrls?
    public let images: [SpotifyImage]
    public let owner: SpotifyPublicUser

    public let isPublic: Bool?
    public let snapshotId: String?
    public let followers: SpotifyFollowers?
    public let tracks: Page<PlaylistTrackItem>

    enum CodingKeys: String, CodingKey {
        case id, name, href, uri, collaborative, description, externalUrls,
            images, owner
        case isPublic = "public"
        case snapshotId, followers, tracks
    }
}

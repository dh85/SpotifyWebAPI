import Foundation

/// Lightweight playlist model returned by:
/// - GET /v1/me/playlists
/// - GET /v1/users/{id}/playlists
public struct SimplifiedPlaylist: Codable, Sendable, Equatable {
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
    public let tracks: PlaylistTracksRef

    enum CodingKeys: String, CodingKey {
        case id, name, href, uri, collaborative, description, externalUrls,
            images, owner
        case isPublic = "public"  // special JSON key
        case snapshotId, tracks
    }
}

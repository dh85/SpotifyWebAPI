import Foundation

/// Track object embedded inside PlaylistTrackItem.
public struct PlaylistTrack: Codable, Sendable, Equatable {
    public let id: String?
    public let name: String
    public let href: URL?
    public let uri: String?
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls?
    public let artists: [SimplifiedArtist]
    public let album: SimplifiedAlbum
}

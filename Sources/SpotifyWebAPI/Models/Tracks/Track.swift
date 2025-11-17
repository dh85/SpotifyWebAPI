import Foundation

/// A Full Track Object.
public struct Track: Codable, Sendable, Equatable {
    public let id: String?
    public let name: String
    public let href: URL?
    public let uri: String?
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls?
    public let artists: [SimplifiedArtist]
    public let album: SimplifiedAlbum
    public let popularity: Int?
    public let previewUrl: URL?
    public let trackNumber: Int?
    public let externalIds: SpotifyExternalIds?
}

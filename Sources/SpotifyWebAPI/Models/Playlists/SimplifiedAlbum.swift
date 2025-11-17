import Foundation

/// Minimal album model embedded inside playlist tracks.
public struct SimplifiedAlbum: Codable, Sendable, Equatable {
    public let id: String?
    public let name: String
    public let href: URL?
    public let uri: String?
    public let albumType: String?
    public let totalTracks: Int?
    public let images: [SpotifyImage]
    public let externalUrls: SpotifyExternalUrls?
}

import Foundation

/// Minimal artist model embedded inside playlist tracks.
public struct SimplifiedArtist: Codable, Sendable, Equatable {
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL?
    public let id: String?
    public let name: String?
    public let type: SpotifyObjectType?
    public let uri: String?
}

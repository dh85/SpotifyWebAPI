import Foundation

/// Minimal artist model embedded inside playlist tracks.
public struct SimplifiedArtist: Codable, Sendable, Equatable {
    public let id: String?
    public let name: String
    public let href: URL?
    public let externalUrls: SpotifyExternalUrls?
}

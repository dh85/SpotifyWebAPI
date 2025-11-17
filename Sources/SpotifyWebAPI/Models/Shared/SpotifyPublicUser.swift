import Foundation

public struct SpotifyPublicUser: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String?
    public let href: URL?
    public let externalUrls: SpotifyExternalUrls?
}

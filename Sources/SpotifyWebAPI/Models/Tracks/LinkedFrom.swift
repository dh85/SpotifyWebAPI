import Foundation

public struct LinkedFrom: Codable, Sendable, Equatable {
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL?
    public let id: String?
    public let type: SpotifyObjectType?
    public let uri: String?
}

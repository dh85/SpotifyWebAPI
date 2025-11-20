import Foundation

/// Minimal album model embedded inside playlist tracks.
public struct SimplifiedAlbum: Codable, Sendable, Equatable {
    public let albumType: AlbumType
    public let totalTracks: Int
    public let availableMarkets: [String]
    public let externalUrls: SpotifyExternalUrls
    public let href: URL
    public let id: String
    public let images: [SpotifyImage]
    public let name: String
    public let releaseDate: String
    public let releaseDatePrecision: ReleaseDatePrecision
    public let restrictions: Restriction?
    public let type: SpotifyObjectType
    public let uri: String
    public let artists: [SimplifiedArtist]
    public let albumGroup: AlbumGroup?
}

public enum AlbumGroup: String, Codable, Sendable, Equatable {
    case album, single, compilation
    case appearsOn = "appears_on"
}

import Foundation

/// A Full Album Object.
/// Source: GET /v1/albums/{id}
public struct Album: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let href: URL
    public let uri: String
    public let albumType: String
    public let artists: [SimplifiedArtist]
    public let images: [SpotifyImage]
    public let releaseDate: String
    public let releaseDatePrecision: String
    public let totalTracks: Int
    public let externalUrls: SpotifyExternalUrls?
    public let tracks: Page<SimplifiedTrack>
    public let copyrights: [SpotifyCopyright]?
    public let externalIds: SpotifyExternalIds?
    public let genres: [String]?
    public let label: String?
    public let popularity: Int?
}

/// Spotify Copyright Object
public struct SpotifyCopyright: Codable, Sendable, Equatable {
    public let text: String
    public let type: String // "C" (Copyright) or "P" (Performance)
}

/// Spotify External IDs Object
public struct SpotifyExternalIds: Codable, Sendable, Equatable {
    public let isrc: String?
    public let ean: String?
    public let upc: String?
}

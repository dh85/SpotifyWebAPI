import Foundation

/// A Full Album Object.
/// Source: GET /v1/albums/{id}
public struct Album: Codable, Sendable, Equatable {
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
    public let type: MediaType
    public let uri: String
    public let artists: [SimplifiedArtist]
    public let tracks: Page<SimplifiedTrack>
    public let copyrights: [SpotifyCopyright]
    public let externalIds: SpotifyExternalIds

    public let label: String
    public let popularity: Int

    @available(
        *,
        deprecated,
        message:
            "Genres are no longer provided by Spotify at the album level. The array is always empty."
    )
    public let genres: [String]
}

extension Album {
    
}

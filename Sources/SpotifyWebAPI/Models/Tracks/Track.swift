import Foundation

/// A Full Track Object.
public struct Track: Codable, Sendable, Equatable {
    public let album: SimplifiedAlbum?
    public let artists: [SimplifiedArtist]?
    public let availableMarkets: [String]?
    public let discNumber: Int?
    public let durationMs: Int?
    public let explicit: Bool?
    public let externalIds: SpotifyExternalIds?
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL?
    public let id: String?
    public let isPlayable: Bool?
    public let linkedFrom: LinkedFrom?
    public let restrictions: Restriction?
    public let name: String?
    public let popularity: Int?
    public let trackNumber: Int?
    public let type: MediaType?
    public let uri: String?
    public let isLocal: Bool?

    @available(
        *,
        deprecated,
        message:
            "Deprecated by Spotify. Spotify Audio preview clips can not be a standalone service."
    )
    public let previewUrl: URL?

}

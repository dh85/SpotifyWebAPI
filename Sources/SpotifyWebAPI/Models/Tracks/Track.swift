import Foundation

/// A full track object.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
public struct Track: Codable, Sendable, Equatable {
    /// The album on which the track appears.
    public let album: SimplifiedAlbum
    /// Artists who performed the track.
    public let artists: [SimplifiedArtist]
    /// Markets where the track is available (ISO 3166-1 alpha-2 codes).
    /// Only present when market is not provided in the request.
    public let availableMarkets: [String]?
    /// Disc number (usually 1).
    public let discNumber: Int
    /// Track length in milliseconds.
    public let durationMs: Int
    /// Whether the track has explicit content.
    public let explicit: Bool
    /// External IDs (e.g., ISRC, EAN, UPC).
    public let externalIds: SpotifyExternalIds
    /// External URLs for this track.
    public let externalUrls: SpotifyExternalUrls
    /// API endpoint URL for full track details.
    public let href: URL
    /// The Spotify ID.
    public let id: String
    /// Whether the track is playable in the given market.
    /// Only present when market is provided in the request.
    public let isPlayable: Bool?
    /// Track linking information.
    /// Only present for relinked tracks.
    public let linkedFrom: LinkedFrom?
    /// Content restriction information.
    /// Only present when content has restrictions.
    public let restrictions: Restriction?
    /// Track name.
    public let name: String
    /// Popularity score (0-100).
    public let popularity: Int
    /// Track number on the disc.
    public let trackNumber: Int
    /// Object type (always "track").
    public let type: SpotifyObjectType
    /// The Spotify URI.
    public let uri: String
    /// Whether the track is from a local file.
    public let isLocal: Bool

    @available(
        *,
        deprecated,
        message:
            "Deprecated by Spotify. Spotify Audio preview clips can not be a standalone service."
    )
    public let previewUrl: URL?

}

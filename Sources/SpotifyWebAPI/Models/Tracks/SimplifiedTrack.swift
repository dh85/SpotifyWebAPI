import Foundation

/// A Simplified Track Object.
/// (Returned when fetching a full album).
public struct SimplifiedTrack: Codable, Sendable, Equatable {
    public let artists: [SimplifiedArtist]
    public let availableMarkets: [String]?
    public let discNumber: Int?
    public let durationMs: Int?
    public let explicit: Bool?
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL?
    public let id: String?
    public let isPlayable: Bool?
    public let linkedFrom: LinkedFrom?
    public let restrictions: Restriction?
    public let name: String?
    public let trackNumber: Int?
    public let type: MediaType?
    public let uri: String?
    public let isLocal: Bool?
}

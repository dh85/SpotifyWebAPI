import Foundation

/// A Simplified Track Object.
/// (Returned when fetching a full album).
public struct SimplifiedTrack: Codable, Sendable, Equatable {
    public let artists: [SimplifiedArtist]
    public let discNumber: Int
    public let durationMs: Int
    public let explicit: Bool
    public let externalUrls: SpotifyExternalUrls?
    public let href: URL?
    public let id: String?
    public let name: String
    public let previewUrl: URL?
    public let trackNumber: Int
    public let uri: String?

    // Note: Spotify's API might include `is_playable` or `linked_from`,
    // which you can add here if needed.
}

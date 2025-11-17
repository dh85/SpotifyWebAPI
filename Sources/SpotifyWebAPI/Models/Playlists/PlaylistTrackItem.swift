import Foundation

/// Individual playlist item representing a track entry.
/// Wraps metadata like added_at, added_by, is_local, etc.
public struct PlaylistTrackItem: Codable, Sendable, Equatable {
    public let addedAt: Date?
    public let addedBy: SpotifyPublicUser?
    public let isLocal: Bool
    public let track: PlaylistTrack?
}

import Foundation

/// A playlist track object containing information about a track or episode in a playlist.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-playlists-tracks)
public struct PlaylistTrackItem: Codable, Sendable, Equatable {
    /// The date and time the track or episode was added.
    public let addedAt: Date?
    /// The Spotify user who added the track or episode.
    public let addedBy: SpotifyPublicUser?
    /// Whether this track or episode is a local file or not.
    public let isLocal: Bool
    /// Information about the track or episode.
    public let track: PlaylistTrack?
}

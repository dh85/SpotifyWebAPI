import Foundation

/// Official Spotify Web API OAuth scopes.
/// Strongly typed so users cannot make mistakes in strings.
/// Matches: https://developer.spotify.com/documentation/web-api/concepts/scopes
public enum SpotifyScope: String, CaseIterable, Sendable, Hashable {
    // MARK: - Playlists
    case playlistModifyPrivate = "playlist-modify-private"
    case playlistModifyPublic = "playlist-modify-public"
    case playlistReadCollaborative = "playlist-read-collaborative"
    case playlistReadPrivate = "playlist-read-private"

    // MARK: - Users
    case userFollowModify = "user-follow-modify"
    case userFollowRead = "user-follow-read"
    case userLibraryRead = "user-library-read"
    case userLibraryModify = "user-library-modify"
    case userReadEmail = "user-read-email"
    case userReadPrivate = "user-read-private"
    case userTopRead = "user-top-read"

    // MARK: - Playback (player)
    case appRemoteControl = "app-remote-control"
    case streaming = "streaming"
    case userModifyPlaybackState = "user-modify-playback-state"
    case userReadCurrentlyPlaying = "user-read-currently-playing"
    case userReadPlaybackPosition = "user-read-playback-position"
    case userReadPlaybackState = "user-read-playback-state"
    case userReadRecentlyPlayed = "user-read-recently-played"
}

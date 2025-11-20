import Foundation

/// Search results containing paginated items for each requested type.
///
/// Only the fields corresponding to the requested search types will be populated.
/// For example, if you search for `[.track, .artist]`, only `tracks` and `artists` will be non-nil.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/search)
public struct SearchResults: Codable, Sendable, Equatable {
    /// Paginated track results, present only if `track` was included in the search types.
    public let tracks: Page<Track>?
    /// Paginated artist results, present only if `artist` was included in the search types.
    public let artists: Page<Artist>?
    /// Paginated album results, present only if `album` was included in the search types.
    public let albums: Page<SimplifiedAlbum>?
    /// Paginated playlist results, present only if `playlist` was included in the search types.
    public let playlists: Page<SimplifiedPlaylist>?
    /// Paginated show results, present only if `show` was included in the search types.
    public let shows: Page<SimplifiedShow>?
    /// Paginated episode results, present only if `episode` was included in the search types.
    public let episodes: Page<SimplifiedEpisode>?
    /// Paginated audiobook results, present only if `audiobook` was included in the search types.
    public let audiobooks: Page<SimplifiedAudiobook>?
}

import Foundation

/// The response from a 'GET /v1/search' request.
///
/// Contains paged results for each category requested.
public struct SearchResults: Codable, Sendable, Equatable {
    public let tracks: Page<Track>?
    public let artists: Page<Artist>?
    public let albums: Page<SimplifiedAlbum>?
    public let playlists: Page<SimplifiedPlaylist>?
    public let shows: Page<SimplifiedShow>?
    public let episodes: Page<SimplifiedEpisode>?
    public let audiobooks: Page<SimplifiedAudiobook>?
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Model Convenience Properties Tests")
struct ModelConvenienceTests {

    @Test("SimplifiedTrack artistNames and durationFormatted")
    func simplifiedTrackConvenience() throws {
        let data = try TestDataLoader.load("album_tracks")
        let page: Page<SimplifiedTrack> = try decodeModel(from: data)
        let track = page.items[0]
        
        #expect(!track.artistNames.isEmpty)
        #expect(track.durationFormatted.contains(":"))
    }

    @Test("Track artistNames and durationFormatted")
    func trackConvenience() throws {
        let track: Track = try decodeModel(from: try TestDataLoader.load("track_full"))
        
        #expect(!track.artistNames.isEmpty)
        #expect(track.durationFormatted.contains(":"))
        
        let minutes = track.durationMs / 60000
        let seconds = (track.durationMs % 60000) / 1000
        let expected = String(format: "%d:%02d", minutes, seconds)
        #expect(track.durationFormatted == expected)
    }

    @Test("SimplifiedAlbum artistNames")
    func simplifiedAlbumConvenience() throws {
        let album: SimplifiedAlbum = try decodeModel(from: try TestDataLoader.load("simplified_album_full"))
        
        #expect(!album.artistNames.isEmpty)
    }

    @Test("Album artistNames")
    func albumConvenience() throws {
        let album: Album = try decodeModel(from: try TestDataLoader.load("album_full"))
        
        #expect(!album.artistNames.isEmpty)
    }

    @Test("SimplifiedEpisode durationFormatted")
    func simplifiedEpisodeConvenience() throws {
        let data = try TestDataLoader.load("show_episodes")
        let page: Page<SimplifiedEpisode> = try decodeModel(from: data)
        let episode = page.items[0]
        
        #expect(episode.durationFormatted.contains(":"))
        
        let minutes = episode.durationMs / 60000
        let seconds = (episode.durationMs % 60000) / 1000
        let expected = String(format: "%d:%02d", minutes, seconds)
        #expect(episode.durationFormatted == expected)
    }

    @Test("Episode durationFormatted")
    func episodeConvenience() throws {
        let episode: Episode = try decodeModel(from: try TestDataLoader.load("episode_full"))
        
        #expect(episode.durationFormatted.contains(":"))
        
        let minutes = episode.durationMs / 60000
        let seconds = (episode.durationMs % 60000) / 1000
        let expected = String(format: "%d:%02d", minutes, seconds)
        #expect(episode.durationFormatted == expected)
    }

    @Test("Playlist totalTracks and isEmpty")
    func playlistConvenience() throws {
        let playlist: Playlist = try decodeModel(from: try TestDataLoader.load("playlist_full"))
        
        #expect(playlist.totalTracks == playlist.tracks.total)
        #expect(playlist.isEmpty == (playlist.tracks.total == 0))
    }

    @Test("SimplifiedPlaylist totalTracks and isEmpty")
    func simplifiedPlaylistConvenience() throws {
        let data = try TestDataLoader.load("playlists_user")
        let page: Page<SimplifiedPlaylist> = try decodeModel(from: data)
        let playlist = page.items[0]
        
        #expect(playlist.totalTracks == (playlist.tracks?.total ?? 0))
        #expect(playlist.isEmpty == (playlist.tracks?.total == 0))
    }
}

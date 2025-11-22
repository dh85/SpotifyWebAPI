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

        #expect(track.artistNames?.isEmpty == false)
        #expect(track.durationFormatted?.contains(":") == true)
    }

    @Test("Track artistNames and durationFormatted")
    func trackConvenience() throws {
        let track: Track = try decodeModel(from: try TestDataLoader.load("track_full"))

        #expect(track.artistNames?.isEmpty == false)
        #expect(track.durationFormatted?.contains(":") == true)

        if let durationMs = track.durationMs {
            let minutes = durationMs / 60000
            let seconds = (durationMs % 60000) / 1000
            let expected = String(format: "%d:%02d", minutes, seconds)
            #expect(track.durationFormatted == expected)
        }
    }

    @Test
    func trackConvenienceNoArtistReturnsNil() throws {
        let track = Track(
            album: nil,
            artists: nil,
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 200_000,
            explicit: false,
            externalIds: nil,
            externalUrls: nil,
            href: nil,
            id: nil,
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Test Track",
            popularity: nil,
            trackNumber: 1,
            type: .track,
            uri: nil,
            isLocal: false
        )

        #expect(track.artistNames == nil)
    }

    @Test("SimplifiedAlbum artistNames")
    func simplifiedAlbumConvenience() throws {
        let album: SimplifiedAlbum = try decodeModel(
            from: try TestDataLoader.load("simplified_album_full"))

        #expect(album.artistNames?.isEmpty == false)
    }

    @Test("Album artistNames")
    func albumConvenience() throws {
        let album: Album = try decodeModel(from: try TestDataLoader.load("album_full"))

        #expect(album.artistNames?.isEmpty == false)
    }

    @Test("SimplifiedEpisode durationFormatted")
    func simplifiedEpisodeConvenience() throws {
        let data = try TestDataLoader.load("show_episodes")
        let page: Page<SimplifiedEpisode> = try decodeModel(from: data)
        let episode = page.items[0]

        #expect(episode.durationFormatted?.contains(":") == true)

        if let durationMs = episode.durationMs {
            let minutes = durationMs / 60000
            let seconds = (durationMs % 60000) / 1000
            let expected = String(format: "%d:%02d", minutes, seconds)
            #expect(episode.durationFormatted == expected)
        }
    }

    @Test("Episode durationFormatted")
    func episodeConvenience() throws {
        let episode: Episode = try decodeModel(from: try TestDataLoader.load("episode_full"))

        #expect(episode.durationFormatted?.contains(":") == true)

        if let durationMs = episode.durationMs {
            let minutes = durationMs / 60000
            let seconds = (durationMs % 60000) / 1000
            let expected = String(format: "%d:%02d", minutes, seconds)
            #expect(episode.durationFormatted == expected)
        }
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

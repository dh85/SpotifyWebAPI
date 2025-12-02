import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SpotifyResourceModelsTests {

    @Test
    func albumMirrorsResourceFields() throws {
        let album: Album = try decodeFixture("album_full")

        #expect(album.hrefURL == album.href)
        #expect(album.spotifyID == album.id)
        #expect(album.displayName == album.name)
        #expect(album.objectType == album.type)
        #expect(album.spotifyURI == album.uri)
    }

    @Test
    func simplifiedAlbumMirrorsResourceFields() throws {
        let album: SimplifiedAlbum = try decodeFixture("simplified_album_full")

        #expect(album.hrefURL == album.href)
        #expect(album.spotifyID == album.id)
        #expect(album.displayName == album.name)
        #expect(album.objectType == album.type)
        #expect(album.spotifyURI == album.uri)
    }

    @Test
    func simplifiedArtistMirrorsResourceFields() throws {
        let album: Album = try decodeFixture("album_full")
        let artist = try #require(album.artists?.first)

        #expect(artist.hrefURL == artist.href)
        #expect(artist.spotifyID == artist.id)
        #expect(artist.displayName == artist.name)
        #expect(artist.objectType == artist.type)
        #expect(artist.spotifyURI == artist.uri)
    }

    @Test
    func playlistMirrorsResourceFields() throws {
        let playlist: Playlist = try decodeFixture("playlist_full")

        #expect(playlist.hrefURL == playlist.href)
        #expect(playlist.spotifyID == playlist.id)
        #expect(playlist.displayName == playlist.name)
        #expect(playlist.objectType == playlist.type)
        #expect(playlist.spotifyURI == playlist.uri)
    }

    @Test
    func simplifiedPlaylistMirrorsResourceFields() throws {
        let page: Page<SimplifiedPlaylist> = try decodeFixture("playlists_user")
        let playlist = try #require(page.items.first)

        #expect(playlist.hrefURL == playlist.href)
        #expect(playlist.spotifyID == playlist.id)
        #expect(playlist.displayName == playlist.name)
        #expect(playlist.objectType == playlist.type)
        #expect(playlist.spotifyURI == playlist.uri)
    }
}

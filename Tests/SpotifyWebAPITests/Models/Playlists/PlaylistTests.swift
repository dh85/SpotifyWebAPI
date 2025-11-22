import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTests {

    @Test
    func decodesPlaylistFixture() throws {
        let data = try TestDataLoader.load("playlist_full")
        let playlist: Playlist = try decodeModel(from: data)

        #expect(playlist.id == "playlist123")
        #expect(playlist.name == "Test Playlist")
        #expect(playlist.owner?.id == "user123")
        #expect(playlist.tracks.total == 10)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedPlaylistTests {

    @Test
    func decodesSimplifiedPlaylistFixture() throws {
        let data = try TestDataLoader.load("playlists_user")
        let page: Page<SimplifiedPlaylist> = try decodeModel(from: data)

        let playlist = try #require(page.items.first)
        #expect(playlist.id == "playlist1")
        #expect(playlist.name == "Playlist 1")
        #expect(playlist.collaborative == false)
        #expect(playlist.snapshotId == "snapshot123")
    }
}

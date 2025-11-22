import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTrackItemTests {

    @Test
    func decodesPlaylistTrackItems() throws {
        let data = try TestDataLoader.load("playlist_tracks")
        let page: Page<PlaylistTrackItem> = try decodeModel(from: data)

        #expect(page.items.count == 1)
        let item = try #require(page.items.first)
        #expect(item.track != nil)
        #expect(item.isLocal == false)
        #expect(item.addedBy?.id == "user123")
    }
}

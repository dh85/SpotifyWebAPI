import Foundation
import Testing
@testable import SpotifyKit

@Suite("SpotifyTestFixtures")
struct SpotifyTestFixturesTests {

    @Test
    func buildsProfile() {
        let profile = SpotifyTestFixtures.currentUserProfile(
            id: "fixtures-user",
            displayName: "Fixtures User",
            product: "free"
        )

        #expect(profile.id == "fixtures-user")
        #expect(profile.displayName == "Fixtures User")
        #expect(profile.product == "free")
        #expect(profile.type == .user)
    }

    @Test
    func buildsSimplifiedPlaylist() {
        let playlist = SpotifyTestFixtures.simplifiedPlaylist(
            id: "fixtures-playlist",
            name: "Fixtures Playlist",
            totalTracks: 99
        )

        #expect(playlist.id == "fixtures-playlist")
        #expect(playlist.name == "Fixtures Playlist")
        #expect(playlist.tracks?.total == 99)
        #expect(playlist.type == .playlist)
    }

    @Test
    func buildsPlaybackState() {
        let state = SpotifyTestFixtures.playbackState(
            deviceName: "Fixtures Device",
            isPlaying: true
        )

        #expect(state.device.name == "Fixtures Device")
        #expect(state.isPlaying == true)
        #expect(state.currentlyPlayingType == .ad)
        #expect(state.actions.skippingNext == false)
    }

    @Test
    func buildsPlaylistsPage() {
        let playlists = [
            SpotifyTestFixtures.simplifiedPlaylist(id: "one"),
            SpotifyTestFixtures.simplifiedPlaylist(id: "two"),
            SpotifyTestFixtures.simplifiedPlaylist(id: "three")
        ]
        let page = SpotifyTestFixtures.playlistsPage(
            playlists: playlists,
            limit: 2,
            offset: 1,
            total: 5
        )

        #expect(page.items.map(\.id) == ["two", "three"])
        #expect(page.limit == 2)
        #expect(page.offset == 1)
        #expect(page.total == 5)
        #expect(page.next?.absoluteString.contains("offset=3") == true)
    }
}

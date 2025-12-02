import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SimplifiedPlaylistTests {

  @Test
  func decodesSimplifiedPlaylistFixture() throws {
    let page: Page<SimplifiedPlaylist> = try decodeFixture("playlists_user")

    let playlist = try #require(page.items.first)
    #expect(playlist.id == "playlist1")
    #expect(playlist.name == "Playlist 1")
    #expect(playlist.collaborative == false)
    #expect(playlist.snapshotId == "snapshot123")
    try expectCodableRoundTrip(playlist)
  }

  @Test
  func simplifiedPlaylistRoundTripsFixture() throws {
    try expectCodableRoundTrip(SpotifyTestFixtures.simplifiedPlaylist(totalTracks: 5))
  }
}

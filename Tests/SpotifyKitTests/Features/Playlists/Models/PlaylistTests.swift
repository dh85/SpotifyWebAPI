import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PlaylistTests {

  @Test
  func decodesPlaylistFixture() throws {
    let playlist: Playlist = try decodeFixture("playlist_full")

    #expect(playlist.id == "playlist123")
    #expect(playlist.name == "Test Playlist")
    #expect(playlist.owner?.id == "user123")
    #expect(playlist.tracks.total == 10)
    try expectCodableRoundTrip(playlist)
  }

  @Test
  func playlistRoundTripsMinimalExample() throws {
    try expectCodableRoundTrip(Playlist.minimalExample)
  }
}

extension Playlist {
  fileprivate static let minimalExample = Playlist(
    collaborative: false,
    description: nil,
    externalUrls: SpotifyExternalUrls(spotify: nil),
    href: URL(string: "https://api.spotify.com/v1/playlists/min")!,
    id: "min",
    images: [],
    name: "Minimal Playlist",
    owner: nil,
    isPublic: true,
    snapshotId: "snapshot-min",
    tracks: Page(
      href: URL(string: "https://api.spotify.com/v1/playlists/min/tracks")!,
      items: [
        PlaylistTrackItem(
          addedAt: nil,
          addedBy: nil,
          isLocal: false,
          track: .track(.playlistTrackExample)
        )
      ],
      limit: 1,
      next: nil,
      offset: 0,
      previous: nil,
      total: 1
    ),
    type: .playlist,
    uri: "spotify:playlist:min"
  )
}

extension Track {
  fileprivate static let playlistTrackExample = Track(
    album: nil,
    artists: nil,
    availableMarkets: [],
    discNumber: 1,
    durationMs: 180_000,
    explicit: false,
    externalIds: nil,
    externalUrls: nil,
    href: nil,
    id: "track-min",
    isPlayable: true,
    linkedFrom: nil,
    restrictions: nil,
    name: "Minimal Track",
    popularity: nil,
    trackNumber: 1,
    type: .track,
    uri: "spotify:track:track-min",
    isLocal: false
  )
}

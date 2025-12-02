import Foundation
import Testing

@testable import SpotifyKit

@Suite("Model Convenience Properties Tests")
struct ModelConvenienceTests {

  @Test("SimplifiedTrack artistNames and durationFormatted")
  func simplifiedTrackConvenience() throws {
    let track = try loadSimplifiedTrackFromFixture()

    #expect(track.artistNames?.isEmpty == false)
    #expect(track.durationFormatted?.contains(":") == true)
  }

  @Test("Track artistNames and durationFormatted")
  func trackConvenience() throws {
    let track = try loadTrackFromFixture()

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
    let track = try loadTrackFromFixture()
    let artistless = Track(
      album: track.album,
      artists: nil,
      availableMarkets: track.availableMarkets,
      discNumber: track.discNumber,
      durationMs: track.durationMs,
      explicit: track.explicit,
      externalIds: track.externalIds,
      externalUrls: track.externalUrls,
      href: track.href,
      id: track.id,
      isPlayable: track.isPlayable,
      linkedFrom: track.linkedFrom,
      restrictions: track.restrictions,
      name: track.name,
      popularity: track.popularity,
      trackNumber: track.trackNumber,
      type: track.type,
      uri: track.uri,
      isLocal: track.isLocal
    )

    #expect(artistless.artistNames == nil)
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
    #expect(playlist.isEmpty == (playlist.totalTracks == 0))
  }

  @Test
  func simplifiedTrackDurationFormattedNilWhenMissing() throws {
    let track = try loadSimplifiedTrackFromFixture()
    let modified = SimplifiedTrack(
      artists: track.artists,
      availableMarkets: track.availableMarkets,
      discNumber: track.discNumber,
      durationMs: nil,
      explicit: track.explicit,
      externalUrls: track.externalUrls,
      href: track.href,
      id: track.id,
      isPlayable: track.isPlayable,
      linkedFrom: track.linkedFrom,
      restrictions: track.restrictions,
      name: track.name,
      trackNumber: track.trackNumber,
      type: track.type,
      uri: track.uri,
      isLocal: track.isLocal
    )

    #expect(modified.durationFormatted == nil)
  }

  @Test
  func episodeDurationFormattedNilWhenMissing() throws {
    let episode: Episode = try decodeModel(from: try TestDataLoader.load("episode_full"))
    let shortened = Episode(
      description: episode.description,
      htmlDescription: episode.htmlDescription,
      durationMs: nil,
      explicit: episode.explicit,
      externalUrls: episode.externalUrls,
      href: episode.href,
      id: episode.id,
      images: episode.images,
      isExternallyHosted: episode.isExternallyHosted,
      isPlayable: episode.isPlayable,
      languages: episode.languages,
      name: episode.name,
      releaseDate: episode.releaseDate,
      releaseDatePrecision: episode.releaseDatePrecision,
      resumePoint: episode.resumePoint,
      type: episode.type,
      uri: episode.uri,
      restrictions: episode.restrictions,
      show: episode.show
    )

    #expect(shortened.durationFormatted == nil)
  }

  @Test
  func simplifiedPlaylistHandlesMissingTrackCounts() {
    let playlist = SimplifiedPlaylist(
      collaborative: false,
      description: "Test playlist",
      externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://example.com")!),
      href: URL(string: "https://api.spotify.com/v1/playlists/test")!,
      id: "test",
      images: [],
      name: "Test",
      owner: SpotifyPublicUser(
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://example.com")!),
        href: URL(string: "https://api.spotify.com/v1/users/test")!,
        id: "tester",
        type: .user,
        uri: "spotify:user:tester",
        displayName: "Tester"
      ),
      isPublic: true,
      snapshotId: "snapshot",
      tracks: nil,
      type: .playlist,
      uri: "spotify:playlist:test"
    )

    #expect(playlist.totalTracks == 0)
    #expect(playlist.isEmpty == true)
  }
}

// MARK: - Helpers

private func loadSimplifiedTrackFromFixture(index: Int = 0) throws -> SimplifiedTrack {
  let data = try TestDataLoader.load("album_tracks")
  let page: Page<SimplifiedTrack> = try decodeModel(from: data)
  return page.items[index]
}

private func loadTrackFromFixture() throws -> Track {
  try decodeModel(from: try TestDataLoader.load("track_full"))
}

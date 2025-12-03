import Foundation
@testable import SpotifyKit

func createMockSimplifiedPlaylist(name: String) -> SimplifiedPlaylist {
  let json = """
  {
    "collaborative": false,
    "description": "Test description",
    "external_urls": {"spotify": "https://open.spotify.com/playlist/test_id"},
    "href": "https://api.spotify.com/v1/playlists/test_id",
    "id": "test_id",
    "images": [],
    "name": "\(name)",
    "owner": {
      "external_urls": {"spotify": "https://open.spotify.com/user/owner_id"},
      "href": "https://api.spotify.com/v1/users/owner_id",
      "id": "owner_id",
      "type": "user",
      "uri": "spotify:user:owner_id",
      "display_name": "Test Owner"
    },
    "public": true,
    "primary_color": null,
    "snapshot_id": "snapshot",
    "tracks": {
      "href": "https://api.spotify.com/v1/playlists/test_id/tracks",
      "total": 0
    },
    "type": "playlist",
    "uri": "spotify:playlist:test_id"
  }
  """
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try! decoder.decode(SimplifiedPlaylist.self, from: json.data(using: .utf8)!)
}

func createMockPlaylist(name: String, trackCount: Int) -> Playlist {
  let json = """
  {
    "collaborative": false,
    "description": "Test description",
    "external_urls": {"spotify": "https://open.spotify.com/playlist/test_id"},
    "href": "https://api.spotify.com/v1/playlists/test_id",
    "id": "test_id",
    "images": [],
    "name": "\(name)",
    "owner": {
      "external_urls": {"spotify": "https://open.spotify.com/user/owner_id"},
      "href": "https://api.spotify.com/v1/users/owner_id",
      "id": "owner_id",
      "type": "user",
      "uri": "spotify:user:owner_id",
      "display_name": "Test Owner"
    },
    "public": true,
    "primary_color": null,
    "snapshot_id": "snapshot",
    "followers": {"href": null, "total": 0},
    "tracks": {
      "href": "https://api.spotify.com/v1/playlists/test_id/tracks",
      "items": [],
      "limit": 20,
      "next": null,
      "offset": 0,
      "previous": null,
      "total": \(trackCount)
    },
    "type": "playlist",
    "uri": "spotify:playlist:test_id"
  }
  """
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try! decoder.decode(Playlist.self, from: json.data(using: .utf8)!)
}

func createMockTracks(count: Int, durationMs: Int = 180000) -> [PlaylistTrackItem] {
  (1...count).map { i in
    let json = """
    {
      "added_at": "2024-01-01T00:00:00Z",
      "added_by": {
        "external_urls": {"spotify": "https://open.spotify.com/user/user_id"},
        "href": "https://api.spotify.com/v1/users/user_id",
        "id": "user_id",
        "type": "user",
        "uri": "spotify:user:user_id",
        "display_name": "User"
      },
      "is_local": false,
      "track": {
        "album": {
          "album_type": "album",
          "total_tracks": 10,
          "external_urls": {"spotify": "https://open.spotify.com/album/album_\(i)"},
          "href": "https://api.spotify.com/v1/albums/album_\(i)",
          "id": "album_\(i)",
          "images": [],
          "name": "Album \(i)",
          "release_date": "2024-01-01",
          "release_date_precision": "day",
          "type": "album",
          "uri": "spotify:album:album_\(i)",
          "artists": []
        },
        "artists": [{
          "external_urls": {"spotify": "https://open.spotify.com/artist/artist_\(i)"},
          "href": "https://api.spotify.com/v1/artists/artist_\(i)",
          "id": "artist_\(i)",
          "name": "Artist \(i)",
          "type": "artist",
          "uri": "spotify:artist:artist_\(i)"
        }],
        "disc_number": 1,
        "duration_ms": \(durationMs),
        "explicit": false,
        "external_ids": {},
        "external_urls": {"spotify": "https://open.spotify.com/track/track_\(i)"},
        "href": "https://api.spotify.com/v1/tracks/track_\(i)",
        "id": "track_\(i)",
        "is_playable": true,
        "name": "Track \(i)",
        "popularity": 50,
        "track_number": \(i),
        "type": "track",
        "uri": "spotify:track:track_\(i)",
        "is_local": false
      }
    }
    """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return try! decoder.decode(PlaylistTrackItem.self, from: json.data(using: .utf8)!)
  }
}

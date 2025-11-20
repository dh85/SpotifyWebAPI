import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "collaborative": false,
                "description": "Test playlist description",
                "external_urls": {"spotify": "https://open.spotify.com/playlist/test123"},
                "href": "https://api.spotify.com/v1/playlists/test123",
                "id": "test123",
                "images": [{"url": "https://example.com/image.jpg", "height": 640, "width": 640}],
                "name": "Test Playlist",
                "owner": {
                    "id": "user123",
                    "type": "user",
                    "uri": "spotify:user:user123"
                },
                "public": true,
                "snapshot_id": "snap123",
                "tracks": {
                    "href": "https://api.spotify.com/v1/playlists/test123/tracks",
                    "items": [],
                    "limit": 100,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "type": "playlist",
                "uri": "spotify:playlist:test123"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: Playlist = try decodeModel(from: data)

        #expect(playlist.id == "test123")
        #expect(playlist.name == "Test Playlist")
        #expect(playlist.collaborative == false)
        #expect(playlist.description == "Test playlist description")
        #expect(playlist.isPublic == true)
        #expect(playlist.snapshotId == "snap123")
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "collaborative": true,
                "href": "https://api.spotify.com/v1/playlists/min123",
                "id": "min123",
                "images": [],
                "name": "Minimal",
                "owner": {
                    "id": "user456",
                    "type": "user",
                    "uri": "spotify:user:user456"
                },
                "tracks": {
                    "href": "https://api.spotify.com/v1/playlists/min123/tracks",
                    "items": [],
                    "limit": 100,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "type": "playlist",
                "uri": "spotify:playlist:min123"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: Playlist = try decodeModel(from: data)

        #expect(playlist.id == "min123")
        #expect(playlist.description == nil)
        #expect(playlist.externalUrls == nil)
        #expect(playlist.isPublic == nil)
        #expect(playlist.snapshotId == nil)
    }

    @Test
    func decodesPublicFieldCorrectly() throws {
        let json = """
            {
                "collaborative": false,
                "href": "https://api.spotify.com/v1/playlists/pub123",
                "id": "pub123",
                "images": [],
                "name": "Public Test",
                "owner": {
                    "id": "user789",
                    "type": "user",
                    "uri": "spotify:user:user789"
                },
                "public": false,
                "tracks": {
                    "href": "https://api.spotify.com/v1/playlists/pub123/tracks",
                    "items": [],
                    "limit": 100,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "type": "playlist",
                "uri": "spotify:playlist:pub123"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: Playlist = try decodeModel(from: data)

        #expect(playlist.isPublic == false)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "collaborative": false,
                "href": "https://api.spotify.com/v1/playlists/eq123",
                "id": "eq123",
                "images": [],
                "name": "Equal",
                "owner": {
                    "id": "user999",
                    "type": "user",
                    "uri": "spotify:user:user999"
                },
                "tracks": {
                    "href": "https://api.spotify.com/v1/playlists/eq123/tracks",
                    "items": [],
                    "limit": 100,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "type": "playlist",
                "uri": "spotify:playlist:eq123"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist1: Playlist = try decodeModel(from: data)
        let playlist2: Playlist = try decodeModel(from: data)

        #expect(playlist1 == playlist2)
    }
}

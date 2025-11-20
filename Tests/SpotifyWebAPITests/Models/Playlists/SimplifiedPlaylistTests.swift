import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedPlaylistTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "collaborative": true,
                "description": "Test playlist",
                "external_urls": {
                    "spotify": "https://open.spotify.com/playlist/playlist1"
                },
                "href": "https://api.spotify.com/v1/playlists/playlist1",
                "id": "playlist1",
                "images": [
                    {
                        "url": "https://example.com/image.jpg",
                        "height": 640,
                        "width": 640
                    }
                ],
                "name": "My Playlist",
                "owner": {
                    "id": "user1",
                    "type": "user",
                    "uri": "spotify:user:user1"
                },
                "public": false,
                "snapshot_id": "snap123",
                "tracks": {
                    "href": "https://api.spotify.com/v1/playlists/playlist1/tracks",
                    "total": 42
                },
                "type": "playlist",
                "uri": "spotify:playlist:playlist1"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: SimplifiedPlaylist = try decodeModel(from: data)

        #expect(playlist.collaborative == true)
        #expect(playlist.description == "Test playlist")
        #expect(playlist.externalUrls?.spotify?.absoluteString == "https://open.spotify.com/playlist/playlist1")
        #expect(playlist.href.absoluteString == "https://api.spotify.com/v1/playlists/playlist1")
        #expect(playlist.id == "playlist1")
        #expect(playlist.images.count == 1)
        #expect(playlist.name == "My Playlist")
        #expect(playlist.owner.id == "user1")
        #expect(playlist.isPublic == false)
        #expect(playlist.snapshotId == "snap123")
        #expect(playlist.tracks?.total == 42)
        #expect(playlist.type == .playlist)
        #expect(playlist.uri == "spotify:playlist:playlist1")
    }

    @Test
    func decodesWithMinimalFields() throws {
        let json = """
            {
                "collaborative": false,
                "href": "https://api.spotify.com/v1/playlists/playlist2",
                "id": "playlist2",
                "images": [],
                "name": "Empty Playlist",
                "owner": {
                    "id": "user2",
                    "type": "user",
                    "uri": "spotify:user:user2"
                },
                "type": "playlist",
                "uri": "spotify:playlist:playlist2"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: SimplifiedPlaylist = try decodeModel(from: data)

        #expect(playlist.collaborative == false)
        #expect(playlist.description == nil)
        #expect(playlist.externalUrls == nil)
        #expect(playlist.id == "playlist2")
        #expect(playlist.images.isEmpty)
        #expect(playlist.name == "Empty Playlist")
        #expect(playlist.isPublic == nil)
        #expect(playlist.snapshotId == nil)
        #expect(playlist.tracks == nil)
    }

    @Test
    func decodesPublicFieldCorrectly() throws {
        let json = """
            {
                "collaborative": false,
                "href": "https://api.spotify.com/v1/playlists/playlist3",
                "id": "playlist3",
                "images": [],
                "name": "Public Playlist",
                "owner": {
                    "id": "user3",
                    "type": "user",
                    "uri": "spotify:user:user3"
                },
                "public": true,
                "type": "playlist",
                "uri": "spotify:playlist:playlist3"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist: SimplifiedPlaylist = try decodeModel(from: data)

        #expect(playlist.isPublic == true)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "collaborative": false,
                "href": "https://api.spotify.com/v1/playlists/playlist4",
                "id": "playlist4",
                "images": [],
                "name": "Test",
                "owner": {
                    "id": "user4",
                    "type": "user",
                    "uri": "spotify:user:user4"
                },
                "type": "playlist",
                "uri": "spotify:playlist:playlist4"
            }
            """
        let data = json.data(using: .utf8)!
        let playlist1: SimplifiedPlaylist = try decodeModel(from: data)
        let playlist2: SimplifiedPlaylist = try decodeModel(from: data)

        #expect(playlist1 == playlist2)
    }
}

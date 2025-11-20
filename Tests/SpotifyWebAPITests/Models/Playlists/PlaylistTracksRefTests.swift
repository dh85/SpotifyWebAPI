import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTracksRefTests {

    @Test
    func decodesSuccessfully() throws {
        let json = """
            {
                "href": "https://api.spotify.com/v1/playlists/123/tracks",
                "total": 42
            }
            """
        let data = json.data(using: .utf8)!
        let ref = try JSONDecoder().decode(PlaylistTracksRef.self, from: data)

        #expect(ref.href == URL(string: "https://api.spotify.com/v1/playlists/123/tracks"))
        #expect(ref.total == 42)
    }

    @Test
    func decodesWithNullHref() throws {
        let json = """
            {
                "href": null,
                "total": 0
            }
            """
        let data = json.data(using: .utf8)!
        let ref = try JSONDecoder().decode(PlaylistTracksRef.self, from: data)

        #expect(ref.href == nil)
        #expect(ref.total == 0)
    }

    @Test
    func encodesSuccessfully() throws {
        let ref = PlaylistTracksRef(
            href: URL(string: "https://api.spotify.com/v1/playlists/123/tracks"),
            total: 42
        )

        let data = try JSONEncoder().encode(ref)
        let decoded = try JSONDecoder().decode(PlaylistTracksRef.self, from: data)

        #expect(ref == decoded)
    }

    @Test
    func equatableWorksCorrectly() {
        let ref1 = PlaylistTracksRef(
            href: URL(string: "https://api.spotify.com/v1/playlists/123/tracks"),
            total: 42
        )
        let ref2 = PlaylistTracksRef(
            href: URL(string: "https://api.spotify.com/v1/playlists/123/tracks"),
            total: 42
        )
        let ref3 = PlaylistTracksRef(href: nil, total: 0)

        #expect(ref1 == ref2)
        #expect(ref1 != ref3)
    }
}

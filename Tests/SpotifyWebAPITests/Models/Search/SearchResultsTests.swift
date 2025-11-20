import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SearchResultsTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "tracks": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=track",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "artists": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=artist",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "albums": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=album",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "playlists": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=playlist",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "shows": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=show",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "episodes": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=episode",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                },
                "audiobooks": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=audiobook",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                }
            }
            """
        let data = json.data(using: .utf8)!
        let results: SearchResults = try decodeModel(from: data)

        #expect(results.tracks != nil)
        #expect(results.artists != nil)
        #expect(results.albums != nil)
        #expect(results.playlists != nil)
        #expect(results.shows != nil)
        #expect(results.episodes != nil)
        #expect(results.audiobooks != nil)
    }

    @Test
    func decodesWithOnlyTracks() throws {
        let json = """
            {
                "tracks": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=track",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 5
                }
            }
            """
        let data = json.data(using: .utf8)!
        let results: SearchResults = try decodeModel(from: data)

        #expect(results.tracks?.total == 5)
        #expect(results.artists == nil)
        #expect(results.albums == nil)
        #expect(results.playlists == nil)
        #expect(results.shows == nil)
        #expect(results.episodes == nil)
        #expect(results.audiobooks == nil)
    }

    @Test
    func decodesWithMultipleTypes() throws {
        let json = """
            {
                "tracks": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=track",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 10
                },
                "artists": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=artist",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 3
                }
            }
            """
        let data = json.data(using: .utf8)!
        let results: SearchResults = try decodeModel(from: data)

        #expect(results.tracks?.total == 10)
        #expect(results.artists?.total == 3)
        #expect(results.albums == nil)
        #expect(results.playlists == nil)
        #expect(results.shows == nil)
        #expect(results.episodes == nil)
        #expect(results.audiobooks == nil)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "tracks": {
                    "href": "https://api.spotify.com/v1/search?query=test&type=track",
                    "items": [],
                    "limit": 20,
                    "next": null,
                    "offset": 0,
                    "previous": null,
                    "total": 0
                }
            }
            """
        let data = json.data(using: .utf8)!
        let results1: SearchResults = try decodeModel(from: data)
        let results2: SearchResults = try decodeModel(from: data)

        #expect(results1 == results2)
    }
}

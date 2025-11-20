import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedTrackTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "artists": [
                    {
                        "id": "artist1",
                        "name": "Artist 1",
                        "href": "https://api.spotify.com/v1/artists/artist1",
                        "uri": "spotify:artist:artist1",
                        "type": "artist",
                        "external_urls": {}
                    }
                ],
                "available_markets": ["US", "GB"],
                "disc_number": 1,
                "duration_ms": 180000,
                "explicit": false,
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/track1"
                },
                "href": "https://api.spotify.com/v1/tracks/track1",
                "id": "track1",
                "is_playable": true,
                "name": "Test Track",
                "track_number": 5,
                "type": "track",
                "uri": "spotify:track:track1",
                "is_local": false
            }
            """
        let data = json.data(using: .utf8)!
        let track: SimplifiedTrack = try decodeModel(from: data)

        #expect(track.artists.count == 1)
        #expect(track.artists.first?.name == "Artist 1")
        #expect(track.availableMarkets == ["US", "GB"])
        #expect(track.discNumber == 1)
        #expect(track.durationMs == 180000)
        #expect(track.explicit == false)
        #expect(track.id == "track1")
        #expect(track.isPlayable == true)
        #expect(track.name == "Test Track")
        #expect(track.trackNumber == 5)
        #expect(track.type == .track)
        #expect(track.isLocal == false)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "artists": [],
                "disc_number": 1,
                "duration_ms": 200000,
                "explicit": true,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/tracks/track2",
                "id": "track2",
                "name": "Track 2",
                "track_number": 1,
                "type": "track",
                "uri": "spotify:track:track2",
                "is_local": false
            }
            """
        let data = json.data(using: .utf8)!
        let track: SimplifiedTrack = try decodeModel(from: data)

        #expect(track.availableMarkets == nil)
        #expect(track.isPlayable == nil)
        #expect(track.linkedFrom == nil)
        #expect(track.restrictions == nil)
        #expect(track.id == "track2")
        #expect(track.explicit == true)
    }

    @Test
    func equatableWorksCorrectly() {
        let track1 = SimplifiedTrack(
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/t1")!,
            id: "t1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Track",
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:t1",
            isLocal: false
        )
        let track2 = SimplifiedTrack(
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/t1")!,
            id: "t1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Track",
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:t1",
            isLocal: false
        )
        let track3 = SimplifiedTrack(
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/t2")!,
            id: "t2",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Track",
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:t2",
            isLocal: false
        )

        #expect(track1 == track2)
        #expect(track1 != track3)
    }
}

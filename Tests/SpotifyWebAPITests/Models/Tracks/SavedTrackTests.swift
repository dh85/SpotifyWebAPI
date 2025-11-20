import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedTrackTests {

    @Test
    func decodesWithAddedAtField() throws {
        let json = """
            {
                "added_at": "2024-01-15T10:30:00Z",
                "track": {
                    "id": "track123",
                    "name": "Test Track",
                    "duration_ms": 180000,
                    "explicit": false,
                    "href": "https://api.spotify.com/v1/tracks/track123",
                    "uri": "spotify:track:track123",
                    "type": "track",
                    "disc_number": 1,
                    "track_number": 1,
                    "popularity": 50,
                    "is_local": false,
                    "external_ids": {"isrc": "US123"},
                    "external_urls": {},
                    "album": {
                        "id": "a",
                        "name": "A",
                        "album_type": "album",
                        "total_tracks": 1,
                        "available_markets": [],
                        "external_urls": {},
                        "href": "https://api.spotify.com/v1/albums/a",
                        "images": [],
                        "release_date": "2024-01-01",
                        "release_date_precision": "day",
                        "type": "album",
                        "uri": "spotify:album:a",
                        "artists": []
                    },
                    "artists": []
                }
            }
            """
        let data = json.data(using: .utf8)!
        let savedTrack: SavedTrack = try decodeModel(from: data)

        #expect(savedTrack.addedAt.timeIntervalSince1970 == 1_705_314_600)
        #expect(savedTrack.track.id == "track123")
        #expect(savedTrack.track.name == "Test Track")
    }

    @Test
    func encodesCorrectly() throws {
        let track = Track(
            album: SimplifiedAlbum(
                albumType: .album,
                totalTracks: 1,
                availableMarkets: [],
                externalUrls: SpotifyExternalUrls(spotify: nil),
                href: URL(string: "https://api.spotify.com/v1/albums/a")!,
                id: "a",
                images: [],
                name: "A",
                releaseDate: "2024-01-01",
                releaseDatePrecision: .day,
                restrictions: nil,
                type: .album,
                uri: "spotify:album:a",
                artists: [],
                albumGroup: nil
            ),
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalIds: SpotifyExternalIds(isrc: "US123", ean: nil, upc: nil),
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/t1")!,
            id: "t1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Track",
            popularity: 50,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:t1",
            isLocal: false,
            previewUrl: nil
        )
        let savedTrack = SavedTrack(
            addedAt: Date(timeIntervalSince1970: 1_700_000_000),
            track: track
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(savedTrack)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded: SavedTrack = try decoder.decode(SavedTrack.self, from: data)

        #expect(decoded.addedAt.timeIntervalSince1970 == savedTrack.addedAt.timeIntervalSince1970)
        #expect(decoded.track == savedTrack.track)
    }

    @Test
    func equatableWorksCorrectly() {
        let track = Track(
            album: SimplifiedAlbum(
                albumType: .album,
                totalTracks: 1,
                availableMarkets: [],
                externalUrls: SpotifyExternalUrls(spotify: nil),
                href: URL(string: "https://api.spotify.com/v1/albums/a")!,
                id: "a",
                images: [],
                name: "A",
                releaseDate: "2024-01-01",
                releaseDatePrecision: .day,
                restrictions: nil,
                type: .album,
                uri: "spotify:album:a",
                artists: [],
                albumGroup: nil
            ),
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalIds: SpotifyExternalIds(isrc: "US123", ean: nil, upc: nil),
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/t1")!,
            id: "t1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Track",
            popularity: 50,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:t1",
            isLocal: false,
            previewUrl: nil
        )
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let savedTrack1 = SavedTrack(addedAt: date, track: track)
        let savedTrack2 = SavedTrack(addedAt: date, track: track)
        let savedTrack3 = SavedTrack(
            addedAt: Date(timeIntervalSince1970: 1_600_000_000), track: track)

        #expect(savedTrack1 == savedTrack2)
        #expect(savedTrack1 != savedTrack3)
    }
}

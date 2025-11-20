import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PlaylistTrackTests {

    @Test
    func decodesTrackSuccessfully() throws {
        let json = """
            {
                "id": "track1",
                "name": "Test Track",
                "duration_ms": 180000,
                "explicit": false,
                "href": "https://api.spotify.com/v1/tracks/track1",
                "uri": "spotify:track:track1",
                "type": "track",
                "disc_number": 1,
                "track_number": 1,
                "popularity": 50,
                "is_local": false,
                "external_ids": {"isrc": "US123"},
                "external_urls": {
                    "spotify": "https://open.spotify.com/track/track1"
                },
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
            """
        let data = json.data(using: .utf8)!
        let playlistTrack: PlaylistTrack = try decodeModel(from: data)

        if case .track(let track) = playlistTrack {
            #expect(track.id == "track1")
            #expect(track.name == "Test Track")
        } else {
            Issue.record("Expected track case")
        }
    }

    @Test
    func throwsErrorForInvalidJSON() throws {
        let json = """
            {
                "id": "invalid",
                "type": "invalid_type"
            }
            """
        let data = json.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            _ = try decodeModel(from: data) as PlaylistTrack
        }
    }

    @Test
    func encodesTrackSuccessfully() throws {
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
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/track/track1")),
            href: URL(string: "https://api.spotify.com/v1/tracks/track1")!,
            id: "track1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Test Track",
            popularity: 50,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:track1",
            isLocal: false,
            previewUrl: nil
        )
        let playlistTrack = PlaylistTrack.track(track)

        let encoder = JSONEncoder()
        let data = try encoder.encode(playlistTrack)
        let decoded: PlaylistTrack = try JSONDecoder().decode(PlaylistTrack.self, from: data)

        #expect(playlistTrack == decoded)
    }

    @Test
    func decodesEpisodeSuccessfully() throws {
        let json = """
            {
                "id": "episode1",
                "name": "Test Episode",
                "description": "Episode description",
                "html_description": "<p>Episode description</p>",
                "duration_ms": 1800000,
                "explicit": false,
                "href": "https://api.spotify.com/v1/episodes/episode1",
                "uri": "spotify:episode:episode1",
                "type": "episode",
                "external_urls": {
                    "spotify": "https://open.spotify.com/episode/episode1"
                },
                "images": [],
                "is_externally_hosted": false,
                "languages": ["en"],
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "show": {
                    "id": "show1",
                    "name": "Test Show",
                    "description": "Show description",
                    "html_description": "<p>Show description</p>",
                    "explicit": false,
                    "href": "https://api.spotify.com/v1/shows/show1",
                    "uri": "spotify:show:show1",
                    "type": "show",
                    "external_urls": {},
                    "images": [],
                    "is_externally_hosted": false,
                    "languages": ["en"],
                    "media_type": "audio",
                    "publisher": "Publisher",
                    "available_markets": [],
                    "copyrights": [],
                    "total_episodes": 10
                }
            }
            """
        let data = json.data(using: .utf8)!
        let playlistTrack: PlaylistTrack = try decodeModel(from: data)

        if case .episode(let episode) = playlistTrack {
            #expect(episode.id == "episode1")
            #expect(episode.name == "Test Episode")
        } else {
            Issue.record("Expected episode case")
        }
    }

    @Test
    func encodesEpisodeSuccessfully() throws {
        let episode = Episode(
            description: "Test Episode",
            htmlDescription: "<p>Test Episode</p>",
            durationMs: 1_800_000,
            explicit: false,
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/episode/ep1")),
            href: URL(string: "https://api.spotify.com/v1/episodes/ep1")!,
            id: "ep1",
            images: [],
            isExternallyHosted: false,
            isPlayable: nil,
            languages: ["en"],
            name: "Test Episode",
            releaseDate: "2024-01-01",
            releaseDatePrecision: .day,
            resumePoint: nil,
            type: .episode,
            uri: "spotify:episode:ep1",
            restrictions: nil,
            show: SimplifiedShow(
                availableMarkets: [],
                copyrights: [],
                description: "Show",
                htmlDescription: "Show",
                explicit: false,
                externalUrls: SpotifyExternalUrls(spotify: nil),
                href: URL(string: "https://api.spotify.com/v1/shows/show1")!,
                id: "show1",
                images: [],
                isExternallyHosted: false,
                languages: ["en"],
                mediaType: "audio",
                name: "Show",
                publisher: "Pub",
                type: .show,
                uri: "spotify:show:show1",
                totalEpisodes: 1
            )
        )
        let playlistTrack = PlaylistTrack.episode(episode)

        let encoder = JSONEncoder()
        let data = try encoder.encode(playlistTrack)
        let decoded: PlaylistTrack = try JSONDecoder().decode(PlaylistTrack.self, from: data)

        #expect(playlistTrack == decoded)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let album = SimplifiedAlbum(
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
        )
        let track1 = Track(
            album: album,
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalIds: SpotifyExternalIds(isrc: "US123", ean: nil, upc: nil),
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/track1")!,
            id: "track1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Test Track",
            popularity: 50,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:track1",
            isLocal: false,
            previewUrl: nil
        )
        let track2 = Track(
            album: album,
            artists: [],
            availableMarkets: nil,
            discNumber: 1,
            durationMs: 180000,
            explicit: false,
            externalIds: SpotifyExternalIds(isrc: "US123", ean: nil, upc: nil),
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/tracks/track1")!,
            id: "track1",
            isPlayable: nil,
            linkedFrom: nil,
            restrictions: nil,
            name: "Test Track",
            popularity: 50,
            trackNumber: 1,
            type: .track,
            uri: "spotify:track:track1",
            isLocal: false,
            previewUrl: nil
        )

        let playlistTrack1 = PlaylistTrack.track(track1)
        let playlistTrack2 = PlaylistTrack.track(track2)

        #expect(playlistTrack1 == playlistTrack2)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct TrackTests {

    @Test
    func trackDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("track_full.json")
        let track: Track = try decodeModel(from: testData)
        expectTrackMatches(track, Track.fullExample)
    }

    @Test
    func trackDecodesWithMinimalFields() throws {
        let testData = try TestDataLoader.load("track_minimal.json")
        let track: Track = try decodeModel(from: testData)
        expectTrackMatches(track, Track.minimalExample)
    }

    @Test
    func trackDecodesProductionSample() throws {
        let testData = try TestDataLoader.load("track_prod.json")
        let track: Track = try decodeModel(from: testData)
        #expect(track.trackNumber == 1)
    }

    private func expectTrackMatches(_ actual: Track, _ expected: Track) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
        #expect(actual.durationMs == expected.durationMs)
        #expect(actual.explicit == expected.explicit)
        #expect(actual.popularity == expected.popularity)
        #expect(actual.isLocal == expected.isLocal)
        #expect(actual.isPlayable == expected.isPlayable)
        #expect(actual.trackNumber == expected.trackNumber)
        #expect(actual.discNumber == expected.discNumber)
        #expect(actual.album?.name == expected.album?.name)
        #expect(actual.artists?.first?.name == expected.artists?.first?.name)
        #expect(actual.externalIds?.isrc == expected.externalIds?.isrc)
        #expect(actual.linkedFrom?.id == expected.linkedFrom?.id)
        #expect(actual.restrictions?.reason == expected.restrictions?.reason)
        #expect(
            actual.availableMarkets?.contains("US") == expected.availableMarkets?.contains("US"))
    }
}

extension Track {
    fileprivate static let fullExample = Track(
        album: SimplifiedAlbum(
            albumType: .album,
            totalTracks: 10,
            availableMarkets: ["US"],
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/album/album_id")),
            href: URL(string: "https://api.spotify.com/v1/albums/album_id")!,
            id: "album_id",
            images: [],
            name: "Test Album",
            releaseDate: "2023-01-01",
            releaseDatePrecision: .day,
            restrictions: nil,
            type: .album,
            uri: "spotify:album:album_id",
            artists: [],
            albumGroup: nil
        ),
        artists: [
            SimplifiedArtist(
                externalUrls: SpotifyExternalUrls(
                    spotify: URL(string: "https://open.spotify.com/artist/artist_id")),
                href: URL(string: "https://api.spotify.com/v1/artists/artist_id")!,
                id: "artist_id",
                name: "Test Artist",
                type: .artist,
                uri: "spotify:artist:artist_id"
            )
        ],
        availableMarkets: ["US"],
        discNumber: 1,
        durationMs: 200_000,
        explicit: false,
        externalIds: SpotifyExternalIds(
            isrc: "US-S1Z-23-00001", ean: "1234567890", upc: "0987654321"),
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/track/track_id")),
        href: URL(string: "https://api.spotify.com/v1/tracks/track_id")!,
        id: "track_id",
        isPlayable: true,
        linkedFrom: LinkedFrom(
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/track/linked_id")),
            href: URL(string: "https://api.spotify.com/v1/tracks/linked_id")!,
            id: "linked_id",
            type: .track,
            uri: "spotify:track:linked_id"
        ),
        restrictions: Restriction(reason: .market),
        name: "Test Track",
        popularity: 75,
        trackNumber: 5,
        type: .track,
        uri: "spotify:track:track_id",
        isLocal: false
    )

    fileprivate static let minimalExample = Track(
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
        durationMs: 180_000,
        explicit: false,
        externalIds: SpotifyExternalIds(isrc: "US123", ean: nil, upc: nil),
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/track/track_id")),
        href: URL(string: "https://api.spotify.com/v1/tracks/track_id")!,
        id: "track_id",
        isPlayable: nil,
        linkedFrom: nil,
        restrictions: nil,
        name: "Minimal Track",
        popularity: 50,
        trackNumber: 1,
        type: .track,
        uri: "spotify:track:track_id",
        isLocal: false
    )
}

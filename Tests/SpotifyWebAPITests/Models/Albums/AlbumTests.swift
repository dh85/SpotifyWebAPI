import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AlbumTests {

    @Test(
        "Album model tests",
        arguments: [
            ("album_full.json", Album.fullExample),
            ("album_minimal.json", .minimalExample),
        ]
    )
    func album_decodesAllRequiredAndOptionalFields(
        test: (file: String, example: Album)
    ) throws {
        let testData = try TestDataLoader.load(test.file)
        let album: Album = try decodeModel(from: testData)
        #expect(album == test.example)
    }

    @Test func decodesUserFromSpotifyDocumentationSample() throws {
        let testData = try TestDataLoader.load("main_album.json")
        let album: Album = try decodeModel(from: testData)
        #expect(album.albumType == .album)
    }
}

extension Album {
    static let fullExample = Album(
        albumType: .album,
        totalTracks: 15,
        availableMarkets: [
            "AT", "BE", "BG", "CY", "CZ", "DE", "EE", "FI", "FR", "GR", "HU",
            "IE", "IT", "LV", "LT", "LU", "MT", "MX", "NL", "NO", "PL", "PT",
            "SK", "ES", "SE", "CH", "TR", "GB", "AD", "LI", "MC", "RO", "IL",
            "ZA", "SA", "AE", "BH", "QA", "OM", "KW", "EG", "MA", "DZ", "TN",
            "LB", "JO", "PS", "BY", "KZ", "MD", "UA", "AL", "BA", "HR", "ME",
            "MK", "RS", "SI", "GH", "KE", "NG", "TZ", "UG", "AM", "BW", "BF",
            "CV", "CW", "GM", "GE", "GW", "LS", "LR", "MW", "ML", "NA", "NE",
            "SM", "ST", "SN", "SC", "SL", "AZ", "BI", "CM", "TD", "KM", "GQ",
            "SZ", "GA", "GN", "KG", "MR", "MN", "RW", "TG", "UZ", "ZW", "BJ",
            "MG", "MU", "MZ", "AO", "CI", "DJ", "ZM", "CD", "CG", "IQ", "LY",
            "TJ", "ET", "XK",
        ],
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/album/fullalbum_id")
        ),
        href: URL(string: "https://api.spotify.com/v1/albums/fullalbum_id")!,
        id: "fullalbum_id",
        images: [
            SpotifyImage(
                url: URL(string: "https://img.spotify.com/1")!,
                height: 640,
                width: 640
            )
        ],
        name: "The Deluxe Test Album",
        releaseDate: "2025-05-15",
        releaseDatePrecision: .day,
        restrictions: Restriction(reason: .explicit),
        type: .album,
        uri: "spotify:album:fullalbum_id",
        artists: [
            SimplifiedArtist(
                externalUrls: nil,
                href: nil,
                id: "artist_a",
                name: "Main Artist",
                type: nil,
                uri: nil
            )
        ],
        tracks: Page(
            href: URL(string: "https://api.spotify.com/v1/albums/fullalbum_id/tracks")!,
            items: [],
            limit: 50,
            next: nil,
            offset: 0,
            previous: nil,
            total: 15
        ),
        copyrights: [
            SpotifyCopyright(
                text: "© 2025 Record Label, Inc.",
                type: .copyright
            ),
            SpotifyCopyright(
                text: "℗ 2025 Record Label, Inc.",
                type: .performance
            ),
        ],
        externalIds: SpotifyExternalIds(
            isrc: "US-S1Z-12-00001",
            ean: nil,
            upc: "123456789012"
        ),
        label: "MegaCorp Records",
        popularity: 85,
        genres: []
    )

    static let minimalExample = Album(
        albumType: .single,
        totalTracks: 1,
        availableMarkets: ["US"],
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/album/min_id")
        ),
        href: URL(string: "https://api.spotify.com/v1/albums/min_id")!,
        id: "min_id",
        images: [],
        name: "Minimal Album",
        releaseDate: "2025-01-01",
        releaseDatePrecision: .year,
        restrictions: nil,
        type: .album,
        uri: "spotify:album:min_id",
        artists: [],
        tracks: Page(
            href: URL(string: "https://api.spotify.com/v1/albums/min_id")!,
            items: [],
            limit: 50,
            next: nil,
            offset: 0,
            previous: nil,
            total: 1
        ),
        copyrights: [],
        externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: nil),
        label: "MegaCorp Records",
        popularity: 0,
        genres: []
    )
}

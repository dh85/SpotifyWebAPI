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
        expectAlbumsEqual(album, test.example)
    }

    private func expectAlbumsEqual(_ actual: Album, _ expected: Album) {
        #expect(actual.albumType == expected.albumType)
        #expect(actual.totalTracks == expected.totalTracks)
        #expect(actual.availableMarkets == expected.availableMarkets)
        #expect(actual.externalUrls == expected.externalUrls)
        #expect(actual.href == expected.href)
        #expect(actual.id == expected.id)
        #expect(actual.images == expected.images)
        #expect(actual.name == expected.name)
        #expect(actual.releaseDate == expected.releaseDate)
        #expect(actual.releaseDatePrecision == expected.releaseDatePrecision)
        #expect(actual.restrictions == expected.restrictions)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
        #expect(actual.artists == expected.artists)
        #expect(actual.tracks.href == expected.tracks.href)
        #expect(actual.tracks.limit == expected.tracks.limit)
        #expect(actual.tracks.next == expected.tracks.next)
        #expect(actual.tracks.offset == expected.tracks.offset)
        #expect(actual.tracks.previous == expected.tracks.previous)
        #expect(actual.tracks.total == expected.tracks.total)
        #expect(actual.copyrights == expected.copyrights)
        #expect(actual.externalIds == expected.externalIds)
        #expect(actual.label == expected.label)
        #expect(actual.popularity == expected.popularity)
    }

    @Test func decodesUserFromSpotifyDocumentationSample() throws {
        let testData = try TestDataLoader.load("main_album.json")
        let album: Album = try decodeModel(from: testData)
        #expect(album.albumType == .album)
    }
}

extension Album {
    fileprivate static let fullExample = Album(
        albumType: .album,
        totalTracks: 18,
        availableMarkets: Self.euMarkets,
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy")
        ),
        href: URL(
            string:
                "https://api.spotify.com/v1/albums/4aawyAB9vmqN3uQ7FjRGTy?locale=en-GB%2Cen%3Bq%3D0.9%2Cen-US%3Bq%3D0.8"
        )!,
        id: "4aawyAB9vmqN3uQ7FjRGTy",
        images: Self.pitbullImages,
        name: "Global Warming",
        releaseDate: "2012-11-16",
        releaseDatePrecision: .day,
        restrictions: nil,
        type: .album,
        uri: "spotify:album:4aawyAB9vmqN3uQ7FjRGTy",
        artists: [Self.pitbullArtist],
        tracks: Self.emptyTracksPage(for: "4aawyAB9vmqN3uQ7FjRGTy", total: 18, isMinimal: false),
        copyrights: [
            SpotifyCopyright(
                text: "(P) 2012 RCA Records, a division of Sony Music Entertainment",
                type: .performance
            )
        ],
        externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: "886443671584"),
        label: "Mr.305/Polo Grounds Music/RCA Records",
        popularity: 53,
        genres: []
    )

    fileprivate static let minimalExample = Album(
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
        tracks: Self.emptyTracksPage(for: "min_id", total: 1, isMinimal: true),
        copyrights: [],
        externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: nil),
        label: "MegaCorp Records",
        popularity: 0,
        genres: []
    )

    fileprivate static let euMarkets = [
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
    ]

    fileprivate static let pitbullImages = [
        SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/ab67616d0000b2732c5b24ecfa39523a75c993c4")!,
            height: 640, width: 640
        ),
        SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/ab67616d00001e022c5b24ecfa39523a75c993c4")!,
            height: 300, width: 300
        ),
        SpotifyImage(
            url: URL(string: "https://i.scdn.co/image/ab67616d000048512c5b24ecfa39523a75c993c4")!,
            height: 64, width: 64
        ),
    ]

    fileprivate static let pitbullArtist = SimplifiedArtist(
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg")
        ),
        href: URL(string: "https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg"),
        id: "0TnOYISbd1XYRBk9myaseg",
        name: "Pitbull",
        type: .artist,
        uri: "spotify:artist:0TnOYISbd1XYRBk9myaseg"
    )

    fileprivate static func emptyTracksPage(for albumId: String, total: Int, isMinimal: Bool)
        -> Page<
            SimplifiedTrack
        >
    {
        Page(
            href: URL(
                string:
                    isMinimal
                    ? "https://api.spotify.com/v1/albums/min_id"
                    : "https://api.spotify.com/v1/albums/\(albumId)/tracks?offset=0&limit=50&locale=en-GB,en;q%3D0.9,en-US;q%3D0.8"
            )!,
            items: [],
            limit: 50,
            next: nil,
            offset: 0,
            previous: nil,
            total: total
        )
    }
}

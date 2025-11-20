import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedAlbumTests {

    @Test
    func decodesWithAllFields() throws {
        let testData = try TestDataLoader.load("simplified_album_full.json")
        let album: SimplifiedAlbum = try decodeModel(from: testData)
        expectAlbumMatches(album, SimplifiedAlbum.testExample)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "album_type": "album",
                "total_tracks": 10,
                "available_markets": ["US", "CA"],
                "external_urls": {
                    "spotify": "https://open.spotify.com/album/test123"
                },
                "href": "https://api.spotify.com/v1/albums/test123",
                "id": "test123",
                "images": [],
                "name": "Test Album",
                "release_date": "2024",
                "release_date_precision": "year",
                "type": "album",
                "uri": "spotify:album:test123",
                "artists": []
            }
            """
        let data = json.data(using: .utf8)!
        let album: SimplifiedAlbum = try decodeModel(from: data)

        #expect(album.id == "test123")
        #expect(album.name == "Test Album")
        #expect(album.restrictions == nil)
        #expect(album.albumGroup == nil)
    }

    @Test
    func albumGroupDecodesCorrectly() throws {
        #expect(AlbumGroup.album.rawValue == "album")
        #expect(AlbumGroup.single.rawValue == "single")
        #expect(AlbumGroup.compilation.rawValue == "compilation")
        #expect(AlbumGroup.appearsOn.rawValue == "appears_on")
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "album_type": "single",
                "total_tracks": 1,
                "available_markets": [],
                "external_urls": {
                    "spotify": "https://open.spotify.com/album/eq123"
                },
                "href": "https://api.spotify.com/v1/albums/eq123",
                "id": "eq123",
                "images": [],
                "name": "Single",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "type": "album",
                "uri": "spotify:album:eq123",
                "artists": []
            }
            """
        let data = json.data(using: .utf8)!
        let album1: SimplifiedAlbum = try decodeModel(from: data)
        let album2: SimplifiedAlbum = try decodeModel(from: data)

        #expect(album1 == album2)
    }

    private func expectAlbumMatches(_ actual: SimplifiedAlbum, _ expected: SimplifiedAlbum) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.totalTracks == expected.totalTracks)
        #expect(actual.releaseDate == expected.releaseDate)
        #expect(actual.albumGroup == expected.albumGroup)
        #expect(actual.albumType == expected.albumType)
        #expect(actual.type == expected.type)
        #expect(actual.availableMarkets == expected.availableMarkets)
        #expect(actual.images.count == expected.images.count)
        #expect(actual.artists.first?.name == expected.artists.first?.name)
        #expect(actual.restrictions?.reason == expected.restrictions?.reason)
        #expect(actual.externalUrls.spotify == expected.externalUrls.spotify)
        #expect(actual.href == expected.href)
    }
}

extension SimplifiedAlbum {
    fileprivate static let testExample = SimplifiedAlbum(
        albumType: .compilation,
        totalTracks: 12,
        availableMarkets: ["US"],
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/album/4xM578d28aF1zXy2jO835t")
        ),
        href: URL(string: "https://api.spotify.com/v1/albums/4xM578d28aF1zXy2jO835t")!,
        id: "4xM578d28aF1zXy2jO835t",
        images: [
            SpotifyImage(
                url: URL(string: "https://example.com/image.jpg")!,
                height: 640,
                width: 640
            )
        ],
        name: "Greatest Hits",
        releaseDate: "2024-01-01",
        releaseDatePrecision: .day,
        restrictions: Restriction(reason: .market),
        type: .album,
        uri: "spotify:album:4xM578d28aF1zXy2jO835t",
        artists: [
            SimplifiedArtist(
                externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/artist/pitbull_id")),
                href: URL(string: "https://api.spotify.com/v1/artists/pitbull_id")!,
                id: "pitbull_id",
                name: "Pitbull",
                type: .artist,
                uri: "spotify:artist:pitbull_id"
            )
        ],
        albumGroup: .appearsOn
    )
}

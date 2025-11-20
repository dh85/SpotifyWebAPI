import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedAlbumTests {

    @Test
    func decodesFromJSON() throws {
        let testData = try TestDataLoader.load("saved_album_item.json")
        let item: SavedAlbum = try decodeModel(from: testData)

        let expected = SavedAlbum.testExample
        #expect(item.album.id == expected.album.id)
        #expect(item.album.name == expected.album.name)
        #expect(item.addedAt == expected.addedAt)
    }

    @Test
    func decodesAddedAtField() throws {
        let json = """
            {
                "added_at": "2024-01-15T10:30:00Z",
                "album": {
                    "album_type": "album",
                    "total_tracks": 5,
                    "available_markets": [],
                    "external_urls": {},
                    "href": "https://api.spotify.com/v1/albums/test",
                    "id": "test",
                    "images": [],
                    "name": "Test",
                    "release_date": "2024",
                    "release_date_precision": "year",
                    "type": "album",
                    "uri": "spotify:album:test",
                    "artists": [],
                    "tracks": {
                        "href": "https://api.spotify.com/v1/albums/test/tracks",
                        "items": [],
                        "limit": 50,
                        "next": null,
                        "offset": 0,
                        "previous": null,
                        "total": 0
                    },
                    "copyrights": [],
                    "external_ids": {},
                    "genres": [],
                    "label": "Label",
                    "popularity": 0
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved: SavedAlbum = try decodeModel(from: data)

        #expect(saved.album.id == "test")
        #expect(saved.addedAt.timeIntervalSince1970 > 0)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "added_at": "2024-01-01T00:00:00Z",
                "album": {
                    "album_type": "single",
                    "total_tracks": 1,
                    "available_markets": [],
                    "external_urls": {},
                    "href": "https://api.spotify.com/v1/albums/eq",
                    "id": "eq",
                    "images": [],
                    "name": "Equal",
                    "release_date": "2024",
                    "release_date_precision": "year",
                    "type": "album",
                    "uri": "spotify:album:eq",
                    "artists": [],
                    "tracks": {
                        "href": "https://api.spotify.com/v1/albums/eq/tracks",
                        "items": [],
                        "limit": 50,
                        "next": null,
                        "offset": 0,
                        "previous": null,
                        "total": 0
                    },
                    "copyrights": [],
                    "external_ids": {},
                    "genres": [],
                    "label": "Label",
                    "popularity": 0
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved1: SavedAlbum = try decodeModel(from: data)
        let saved2: SavedAlbum = try decodeModel(from: data)

        #expect(saved1 == saved2)
    }
}

extension SavedAlbum {
    fileprivate static let testExample = SavedAlbum(
        addedAt: Date(timeIntervalSince1970: 1_704_110_400),
        album: Album(
            albumType: .album,
            totalTracks: 10,
            availableMarkets: ["US"],
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/albums/album123")!,
            id: "album123",
            images: [],
            name: "Test Album",
            releaseDate: "2024-01-01",
            releaseDatePrecision: .day,
            restrictions: nil,
            type: .album,
            uri: "spotify:album:album123",
            artists: [],
            tracks: Page(
                href: URL(string: "https://api.spotify.com/v1/albums/album123/tracks")!,
                items: [],
                limit: 50,
                next: nil,
                offset: 0,
                previous: nil,
                total: 10
            ),
            copyrights: [],
            externalIds: SpotifyExternalIds(isrc: nil, ean: nil, upc: nil),
            label: "Test Label",
            popularity: 50,
            genres: []
        )
    )
}

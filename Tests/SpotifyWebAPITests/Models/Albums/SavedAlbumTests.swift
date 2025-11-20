import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedAlbumTests {

    @Test
    func savedAlbumDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("saved_album_item.json")
        let item: SavedAlbum = try decodeModel(from: testData)

        let expected = SavedAlbum.testExample
        #expect(item.album.id == expected.album.id)
        #expect(item.album.name == expected.album.name)
        #expect(item.addedAt == expected.addedAt)
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

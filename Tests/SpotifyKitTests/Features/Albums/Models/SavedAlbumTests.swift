import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SavedAlbumTests {

    @Test
    func decodesSavedAlbumsPage() throws {
        let data = try TestDataLoader.load("albums_saved")
        let page: Page<SavedAlbum> = try decodeModel(from: data)

        #expect(page.total == 1)
        let saved = try #require(page.items.first)
        #expect(saved.album.id == "album123")
        #expect(saved.album.name == "Test Album")
    }
    
    @Test
    func contentPropertyReturnsAlbum() {
        let saved = SavedAlbum.testExample
        #expect(saved.content.id == saved.album.id)
        #expect(saved.content.name == saved.album.name)
    }
    
    @Test
    func conformsToSavedItemProtocol() {
        let saved = SavedAlbum.testExample
        #expect(saved.addedAt == Date(timeIntervalSince1970: 1_704_110_400))
        #expect(saved.wasAddedAfter(Date(timeIntervalSince1970: 1_704_000_000)))
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
            popularity: 50
        )
    )
}

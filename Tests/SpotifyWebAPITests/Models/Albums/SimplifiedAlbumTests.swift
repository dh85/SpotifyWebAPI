import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedAlbumTests {

    @Test
    func decodes_SimplifiedAlbum_Correctly() throws {
        let testData = try TestDataLoader.load("simplified_album_full.json")

        let album: SimplifiedAlbum = try decodeModel(from: testData)

        #expect(album.id == "4xM578d28aF1zXy2jO835t")
        #expect(album.name == "Greatest Hits")
        #expect(album.totalTracks == 12)
        #expect(album.releaseDate == "2024-01-01")

        #expect(album.albumGroup == .appearsOn)
        #expect(album.albumType == .compilation)
        #expect(album.type == .album)

        // Assert - Collections
        #expect(album.availableMarkets.contains("US"))
        #expect(album.images.count == 1)
        #expect(album.artists.first?.name == "Pitbull")

        // Assert - Optional Nested Objects
        #expect(album.restrictions?.reason == .market)

        #expect(
            album.externalUrls.spotify?.absoluteString.contains(
                "open.spotify.com"
            ) == true
        )
        #expect(album.href.absoluteString.contains("api.spotify.com"))
    }
}

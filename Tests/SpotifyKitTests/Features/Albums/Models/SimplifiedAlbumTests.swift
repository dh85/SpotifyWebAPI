import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SimplifiedAlbumTests {

    @Test
    func decodesSimplifiedAlbumFixture() throws {
        let data = try TestDataLoader.load("simplified_album_full")
        let album: SimplifiedAlbum = try decodeModel(from: data)
        expectAlbumMatches(album, .testExample)
    }

    @Test
    func supportsCodableRoundTrip() throws {
        try expectCodableRoundTrip(SimplifiedAlbum.testExample)
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
        #expect(actual.images?.count == expected.images?.count)
        #expect(actual.artists?.first?.name == expected.artists?.first?.name)
        #expect(actual.restrictions?.reason == expected.restrictions?.reason)
        #expect(actual.externalUrls?.spotify == expected.externalUrls?.spotify)
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
                externalUrls: SpotifyExternalUrls(
                    spotify: URL(string: "https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg")),
                href: URL(string: "https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg")!,
                id: "0TnOYISbd1XYRBk9myaseg",
                name: "Pitbull",
                type: .artist,
                uri: "spotify:artist:0TnOYISbd1XYRBk9myaseg"
            )
        ],
        albumGroup: .appearsOn
    )
}

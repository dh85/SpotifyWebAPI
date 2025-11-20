import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ArtistTests {

    @Test
    func artistDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("artist_full.json")
        let artist: Artist = try decodeModel(from: testData)
        expectArtistMatches(artist, Artist.fullExample)
    }

    @Test
    func artistDecodesWithMissingOptionalFields() throws {
        let data = "{}".data(using: .utf8)!
        let artist: Artist = try decodeModel(from: data)
        expectArtistMatches(artist, Artist.minimalExample)
    }

    private func expectArtistMatches(_ actual: Artist, _ expected: Artist) {
        #expect(actual.externalUrls?.spotify == expected.externalUrls?.spotify)
        #expect(actual.followers?.total == expected.followers?.total)
        #expect(actual.genres == expected.genres)
        #expect(actual.href == expected.href)
        #expect(actual.id == expected.id)
        #expect(actual.images?.count == expected.images?.count)
        if let actualImage = actual.images?.first, let expectedImage = expected.images?.first {
            #expect(actualImage.height == expectedImage.height)
            #expect(actualImage.width == expectedImage.width)
            #expect(actualImage.url == expectedImage.url)
        }
        #expect(actual.name == expected.name)
        #expect(actual.popularity == expected.popularity)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
    }
}

extension Artist {
    fileprivate static let fullExample = Artist(
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg")
        ),
        followers: SpotifyFollowers(href: nil, total: 11_998_682),
        genres: [],
        href: URL(
            string:
                "https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg?locale=en-GB%2Cen%3Bq%3D0.9"
        ),
        id: "0TnOYISbd1XYRBk9myaseg",
        images: [
            SpotifyImage(
                url: URL(
                    string: "https://i.scdn.co/image/ab6761610000e5eb8d8ac7290d0fe2d12fb6e4d9")!,
                height: 640,
                width: 640
            ),
            SpotifyImage(
                url: URL(
                    string: "https://i.scdn.co/image/ab6761610000e5eb8d8ac7290d0fe2d12fb6e4d9")!,
                height: 320,
                width: 320
            ),
            SpotifyImage(
                url: URL(
                    string: "https://i.scdn.co/image/ab6761610000e5eb8d8ac7290d0fe2d12fb6e4d9")!,
                height: 160,
                width: 160
            ),
        ],
        name: "Pitbull",
        popularity: 85,
        type: .artist,
        uri: "spotify:artist:0TnOYISbd1XYRBk9myaseg"
    )

    fileprivate static let minimalExample = Artist(
        externalUrls: nil,
        followers: nil,
        genres: nil,
        href: nil,
        id: nil,
        images: nil,
        name: nil,
        popularity: nil,
        type: nil,
        uri: nil
    )
}

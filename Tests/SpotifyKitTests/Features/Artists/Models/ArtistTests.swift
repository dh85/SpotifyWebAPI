import Foundation
import Testing

@testable import SpotifyKit

@Suite struct ArtistTests {

    @Test
    func artistDecodesCorrectly() throws {
        let artist: Artist = try decodeFixture("artist_full")
        expectArtistMatches(artist, .fullExample)
    }

    @Test
    func artistDecodesWithMissingOptionalFields() throws {
        let json = """
            {
                "genres": [],
                "href": "https://api.spotify.com/v1/artists/minimal",
                "id": "minimal",
                "name": "Minimal Artist",
                "popularity": 0,
                "type": "artist",
                "uri": "spotify:artist:minimal"
            }
            """
        let data = json.data(using: .utf8)!
        let artist: Artist = try decodeModel(from: data)
        expectArtistMatches(artist, .minimalExample)
    }

    @Test
    func artistRoundTrips() throws {
        try expectCodableRoundTrip(Artist.fullExample)
        try expectCodableRoundTrip(Artist.minimalExample)
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
        )!,
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
        genres: [],
        href: URL(string: "https://api.spotify.com/v1/artists/minimal")!,
        id: "minimal",
        images: nil,
        name: "Minimal Artist",
        popularity: 0,
        type: .artist,
        uri: "spotify:artist:minimal"
    )
}

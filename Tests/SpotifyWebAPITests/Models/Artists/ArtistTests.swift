import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ArtistTests {

    @Test
    func decodes_Artist_Correctly() throws {
        let testData = try TestDataLoader.load("artist_full.json")

        let artist: Artist = try decodeModel(from: testData)

        #expect(
            artist.externalUrls?.spotify?.absoluteString
                == "https://open.spotify.com/artist/0TnOYISbd1XYRBk9myaseg"
        )
        #expect(artist.followers?.total == 11_998_682)
        #expect(artist.genres?.isEmpty == true)
        #expect(artist.href?.absoluteString == "https://api.spotify.com/v1/artists/0TnOYISbd1XYRBk9myaseg?locale=en-GB%2Cen%3Bq%3D0.9")
        #expect(artist.id == "0TnOYISbd1XYRBk9myaseg")
        #expect(artist.images?.count == 3)
        let image = try #require(artist.images?.first)
        #expect(image.height == 640)
        #expect(image.width == 640)
        #expect(image.url.absoluteString == "https://i.scdn.co/image/ab6761610000e5eb8d8ac7290d0fe2d12fb6e4d9")
        #expect(artist.name == "Pitbull")
        #expect(artist.popularity == 85)
        #expect(artist.type == .artist)
        #expect(artist.uri == "spotify:artist:0TnOYISbd1XYRBk9myaseg")
    }

    @Test
    func decodes_Artist_withMissingOptionalFields() throws {
        let minimalJSON = "{}"
        let data = minimalJSON.data(using: .utf8)!

        // Act
        let artist: Artist = try decodeModel(from: data)

        #expect(artist.name == nil)
        #expect(artist.popularity == nil)
        #expect(artist.genres == nil)
        #expect(artist.images == nil)
        #expect(artist.followers == nil)
    }


}

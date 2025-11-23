import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedArtistTests {

    @Test
    func decodesSimplifiedArtistFixture() throws {
        let data = try TestDataLoader.load("artist_full")
        let artist: SimplifiedArtist = try decodeModel(from: data)

        #expect(artist.id == "0TnOYISbd1XYRBk9myaseg")
        #expect(artist.name == "Pitbull")
        #expect(artist.type == .artist)
        #expect(artist.externalUrls?.spotify?.absoluteString.contains("open.spotify.com") == true)
    }
}

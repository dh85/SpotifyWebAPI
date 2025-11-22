import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedAudiobookTests {

    @Test
    func decodesSimplifiedAudiobookFixture() throws {
        let data = try TestDataLoader.load("audiobook_full")
        let audiobook: SimplifiedAudiobook = try decodeModel(from: data)

        #expect(audiobook.id == "7iHfbu1YPACw6oZPAFJtqe")
        #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")
        #expect(audiobook.authors.first?.name == "Frank Herbert")
        #expect(audiobook.narrators.first?.name == "Scott Brick")
        #expect(audiobook.totalChapters == 51)
        #expect(audiobook.externalUrls.spotify?.absoluteString.contains("open.spotify.com") == true)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedAudiobookTests {

    @Test
    func decodesSimplifiedAudiobookFixture() throws {
        let audiobook: SimplifiedAudiobook = try decodeFixture("audiobook_full")

        #expect(audiobook.id == "7iHfbu1YPACw6oZPAFJtqe")
        #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")
        #expect(audiobook.authors.first?.name == "Frank Herbert")
        #expect(audiobook.narrators.first?.name == "Scott Brick")
        #expect(audiobook.totalChapters == 51)
        #expect(audiobook.externalUrls.spotify?.absoluteString.contains("open.spotify.com") == true)
        try expectCodableRoundTrip(audiobook)
    }

    @Test
    func minimalSimplifiedAudiobookDecodes() throws {
        let json = """
            {
                "authors": [{"name": "Author"}],
                "available_markets": [],
                "copyrights": [],
                "description": "Desc",
                "html_description": "<p>Desc</p>",
                "edition": null,
                "explicit": false,
                "external_urls": {"spotify": "https://open.spotify.com/audiobook/min"},
                "href": "https://api.spotify.com/v1/audiobooks/min",
                "id": "min",
                "images": [],
                "languages": ["en"],
                "media_type": "audio",
                "name": "Minimal",
                "narrators": [{"name": "Narrator"}],
                "publisher": "Publisher",
                "type": "audiobook",
                "uri": "spotify:audiobook:min",
                "total_chapters": 1
            }
            """
        let audiobook: SimplifiedAudiobook = try decodeModel(from: Data(json.utf8))
        #expect(audiobook.name == "Minimal")
        #expect(audiobook.totalChapters == 1)
        try expectCodableRoundTrip(audiobook)
    }
}

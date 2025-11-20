import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedAudiobookTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "authors": [{"name": "Author Name"}],
                "available_markets": ["US", "CA"],
                "copyrights": [{"text": "Copyright text", "type": "P"}],
                "description": "Test description",
                "html_description": "<p>Test description</p>",
                "edition": "Unabridged",
                "explicit": false,
                "external_urls": {"spotify": "https://open.spotify.com/audiobook/test123"},
                "href": "https://api.spotify.com/v1/audiobooks/test123",
                "id": "test123",
                "images": [{"url": "https://example.com/image.jpg", "height": 640, "width": 640}],
                "languages": ["en"],
                "media_type": "audio",
                "name": "Test Audiobook",
                "narrators": [{"name": "Narrator Name"}],
                "publisher": "Test Publisher",
                "type": "audiobook",
                "uri": "spotify:audiobook:test123",
                "total_chapters": 10
            }
            """
        let data = json.data(using: .utf8)!
        let audiobook: SimplifiedAudiobook = try decodeModel(from: data)

        #expect(audiobook.id == "test123")
        #expect(audiobook.name == "Test Audiobook")
        #expect(audiobook.authors.count == 1)
        #expect(audiobook.narrators.count == 1)
        #expect(audiobook.edition == "Unabridged")
        #expect(audiobook.explicit == false)
        #expect(audiobook.totalChapters == 10)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "authors": [],
                "available_markets": [],
                "copyrights": [],
                "description": "Desc",
                "html_description": "<p>Desc</p>",
                "explicit": true,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/audiobooks/min123",
                "id": "min123",
                "images": [],
                "languages": ["en"],
                "media_type": "audio",
                "name": "Minimal",
                "narrators": [],
                "publisher": "Pub",
                "type": "audiobook",
                "uri": "spotify:audiobook:min123",
                "total_chapters": 1
            }
            """
        let data = json.data(using: .utf8)!
        let audiobook: SimplifiedAudiobook = try decodeModel(from: data)

        #expect(audiobook.id == "min123")
        #expect(audiobook.edition == nil)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "authors": [],
                "available_markets": [],
                "copyrights": [],
                "description": "Equal",
                "html_description": "<p>Equal</p>",
                "explicit": false,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/audiobooks/eq123",
                "id": "eq123",
                "images": [],
                "languages": ["en"],
                "media_type": "audio",
                "name": "Equal",
                "narrators": [],
                "publisher": "Pub",
                "type": "audiobook",
                "uri": "spotify:audiobook:eq123",
                "total_chapters": 5
            }
            """
        let data = json.data(using: .utf8)!
        let audiobook1: SimplifiedAudiobook = try decodeModel(from: data)
        let audiobook2: SimplifiedAudiobook = try decodeModel(from: data)

        #expect(audiobook1 == audiobook2)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AudiobookTests {

    @Test
    func decodes_Audiobook_Full() throws {
        let testData = try TestDataLoader.load("audiobook_full.json")

        let audiobook: Audiobook = try decodeModel(from: testData)

        // Assert - Core Properties
        #expect(audiobook.id == "7iHfbu1YPACw6oZPAFJtqe")
        #expect(audiobook.name == "Dune: Book One in the Dune Chronicles")
        #expect(audiobook.publisher == "Frank Herbert")
        #expect(audiobook.mediaType == "audio")
        #expect(audiobook.totalChapters == 51)
        #expect(audiobook.edition == "Unabridged")
        #expect(audiobook.explicit == false)

        // Assert - Nested Authors & Narrators
        #expect(audiobook.authors.count == 1)
        #expect(audiobook.authors.first?.name == "Frank Herbert")

        #expect(audiobook.narrators.count == 5)
        #expect(audiobook.narrators.first?.name == "Scott Brick")

        // Assert - Collections
        #expect(audiobook.languages == ["en"])
        #expect(audiobook.availableMarkets.contains("US"))

        // Assert - Nested Chapters (Page)
        #expect(audiobook.chapters?.total == 51)
        #expect(audiobook.chapters?.items.first?.name == "Opening Credits")

        // Assert - URLs
        #expect(
            audiobook.externalUrls.spotify?.absoluteString.contains(
                "open.spotify.com"
            ) == true
        )
        #expect(audiobook.uri == "spotify:show:7iHfbu1YPACw6oZPAFJtqe")
    }

    @Test
    func decodes_Audiobook_Minimal() throws {
        let json = """
            {
                "authors": [],
                "available_markets": [],
                "copyrights": [],
                "description": "Desc",
                "html_description": "Desc",
                "explicit": false,
                "external_urls": { "spotify": "u" },
                "href": "h",
                "id": "id",
                "images": [],
                "languages": [],
                "media_type": "audio",
                "name": "Name",
                "narrators": [],
                "publisher": "Pub",
                "type": "audiobook",
                "uri": "uri",
                "total_chapters": 5
            }
            """
        let data = json.data(using: .utf8)!

        let audiobook: Audiobook = try decodeModel(from: data)

        #expect(audiobook.edition == nil)
        #expect(audiobook.chapters == nil)
        #expect(audiobook.name == "Name")
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedAudiobookTests {

    @Test
    func decodesFromJSON() throws {
        let json = """
            {
                "added_at": "2024-01-15T10:30:00Z",
                "audiobook": {
                    "id": "audiobook123",
                    "name": "Test Audiobook",
                    "authors": [{"name": "Test Author"}],
                    "narrators": [{"name": "Test Narrator"}],
                    "publisher": "Test Publisher",
                    "description": "Test description",
                    "edition": "Unabridged",
                    "languages": ["en"],
                    "media_type": "audio",
                    "explicit": false,
                    "total_chapters": 10,
                    "images": [],
                    "available_markets": ["US"],
                    "href": "https://api.spotify.com/v1/audiobooks/audiobook123",
                    "uri": "spotify:audiobook:audiobook123",
                    "external_urls": {"spotify": "https://open.spotify.com/audiobook/audiobook123"},
                    "type": "audiobook",
                    "chapters": {
                        "href": "https://api.spotify.com/v1/audiobooks/audiobook123/chapters",
                        "items": [],
                        "limit": 50,
                        "next": null,
                        "offset": 0,
                        "previous": null,
                        "total": 10
                    },
                    "copyrights": [],
                    "html_description": "<p>Test description</p>"
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved: SavedAudiobook = try decodeModel(from: data)

        #expect(saved.audiobook.id == "audiobook123")
        #expect(saved.addedAt.timeIntervalSince1970 > 0)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "added_at": "2024-01-01T00:00:00Z",
                "audiobook": {
                    "id": "eq123",
                    "name": "Equal Book",
                    "authors": [],
                    "narrators": [],
                    "publisher": "Publisher",
                    "description": "Desc",
                    "edition": "Ed",
                    "languages": ["en"],
                    "media_type": "audio",
                    "explicit": false,
                    "total_chapters": 1,
                    "images": [],
                    "available_markets": [],
                    "href": "https://api.spotify.com/v1/audiobooks/eq123",
                    "uri": "spotify:audiobook:eq123",
                    "external_urls": {},
                    "type": "audiobook",
                    "chapters": {
                        "href": "https://api.spotify.com/v1/audiobooks/eq123/chapters",
                        "items": [],
                        "limit": 50,
                        "next": null,
                        "offset": 0,
                        "previous": null,
                        "total": 0
                    },
                    "copyrights": [],
                    "html_description": ""
                }
            }
            """
        let data = json.data(using: .utf8)!
        let saved1: SavedAudiobook = try decodeModel(from: data)
        let saved2: SavedAudiobook = try decodeModel(from: data)

        #expect(saved1 == saved2)
    }
}

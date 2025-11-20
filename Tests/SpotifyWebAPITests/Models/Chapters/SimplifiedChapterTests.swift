import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedChapterTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "available_markets": ["US", "CA"],
                "chapter_number": 1,
                "description": "Chapter description",
                "html_description": "<p>Chapter description</p>",
                "duration_ms": 300000,
                "explicit": false,
                "external_urls": {"spotify": "https://open.spotify.com/chapter/test123"},
                "href": "https://api.spotify.com/v1/chapters/test123",
                "id": "test123",
                "images": [{"url": "https://example.com/image.jpg", "height": 640, "width": 640}],
                "is_playable": true,
                "languages": ["en"],
                "name": "Chapter 1",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "resume_point": {"fully_played": false, "resume_position_ms": 1000},
                "type": "episode",
                "uri": "spotify:episode:test123",
                "restrictions": {"reason": "market"}
            }
            """
        let data = json.data(using: .utf8)!
        let chapter: SimplifiedChapter = try decodeModel(from: data)

        #expect(chapter.id == "test123")
        #expect(chapter.name == "Chapter 1")
        #expect(chapter.chapterNumber == 1)
        #expect(chapter.durationMs == 300000)
        #expect(chapter.explicit == false)
        #expect(chapter.availableMarkets == ["US", "CA"])
        #expect(chapter.isPlayable == true)
        #expect(chapter.resumePoint?.fullyPlayed == false)
        #expect(chapter.restrictions?.reason == .market)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "chapter_number": 2,
                "description": "Minimal",
                "html_description": "<p>Minimal</p>",
                "duration_ms": 180000,
                "explicit": true,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/chapters/min123",
                "id": "min123",
                "images": [],
                "languages": ["en"],
                "name": "Chapter 2",
                "release_date": "2024",
                "release_date_precision": "year",
                "type": "episode",
                "uri": "spotify:episode:min123"
            }
            """
        let data = json.data(using: .utf8)!
        let chapter: SimplifiedChapter = try decodeModel(from: data)

        #expect(chapter.id == "min123")
        #expect(chapter.availableMarkets == nil)
        #expect(chapter.isPlayable == nil)
        #expect(chapter.resumePoint == nil)
        #expect(chapter.restrictions == nil)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let json = """
            {
                "chapter_number": 3,
                "description": "Equal",
                "html_description": "<p>Equal</p>",
                "duration_ms": 200000,
                "explicit": false,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/chapters/eq123",
                "id": "eq123",
                "images": [],
                "languages": ["en"],
                "name": "Equal",
                "release_date": "2024-01-01",
                "release_date_precision": "day",
                "type": "episode",
                "uri": "spotify:episode:eq123"
            }
            """
        let data = json.data(using: .utf8)!
        let chapter1: SimplifiedChapter = try decodeModel(from: data)
        let chapter2: SimplifiedChapter = try decodeModel(from: data)

        #expect(chapter1 == chapter2)
    }
}

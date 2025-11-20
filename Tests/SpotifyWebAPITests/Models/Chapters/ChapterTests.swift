import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct ChapterTests {

    @Test
    func chapterDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("chapter_full.json")
        let chapter: Chapter = try decodeModel(from: testData)
        expectChapterMatches(chapter, Chapter.fullExample)
    }

    @Test
    func chapterDecodesWithMinimalFields() throws {
        let data = Chapter.minimalJSON.data(using: .utf8)!
        let chapter: Chapter = try decodeModel(from: data)
        expectChapterMatches(chapter, Chapter.minimalExample)
    }

    private func expectChapterMatches(_ actual: Chapter, _ expected: Chapter) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.chapterNumber == expected.chapterNumber)
        #expect(actual.description == expected.description)
        #expect(actual.htmlDescription == expected.htmlDescription)
        #expect(actual.durationMs == expected.durationMs)
        #expect(actual.explicit == expected.explicit)
        #expect(actual.externalUrls.spotify == expected.externalUrls.spotify)
        #expect(actual.href == expected.href)
        #expect(actual.images.count == expected.images.count)
        #expect(actual.isPlayable == expected.isPlayable)
        #expect(actual.languages == expected.languages)
        #expect(actual.releaseDate == expected.releaseDate)
        #expect(actual.releaseDatePrecision == expected.releaseDatePrecision)
        #expect(actual.resumePoint?.fullyPlayed == expected.resumePoint?.fullyPlayed)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
        #expect(actual.restrictions == expected.restrictions)
        #expect(actual.audiobook.id == expected.audiobook.id)
        #expect(actual.availableMarkets == expected.availableMarkets)
    }
}

extension Chapter {
    fileprivate static let fullExample = Chapter(
        availableMarkets: ["US", "CA", "GB"],
        chapterNumber: 1,
        description: "Chapter description",
        htmlDescription: "<p>Chapter description</p>",
        durationMs: 300000,
        explicit: false,
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/episode/chapterid")),
        href: URL(string: "https://api.spotify.com/v1/chapters/chapterid")!,
        id: "chapterid",
        images: [
            SpotifyImage(
                url: URL(string: "https://i.scdn.co/image/image1")!, height: 640, width: 640)
        ],
        isPlayable: true,
        languages: ["en"],
        name: "Chapter 1",
        releaseDate: "2023-01-01",
        releaseDatePrecision: "day",
        resumePoint: ResumePoint(fullyPlayed: false, resumePositionMs: 0),
        type: .chapter,
        uri: "spotify:episode:chapterid",
        restrictions: nil,
        audiobook: Audiobook(
            authors: [Author(name: "Author Name")],
            availableMarkets: ["US"],
            copyrights: [],
            description: "Audiobook description",
            htmlDescription: "Audiobook description",
            edition: nil,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com")),
            href: URL(string: "https://api.spotify.com/v1/audiobooks/audiobookid")!,
            id: "audiobookid",
            images: [],
            languages: ["en"],
            mediaType: "audio",
            name: "Audiobook Name",
            narrators: [],
            publisher: "Publisher",
            type: .audiobook,
            uri: "spotify:audiobook:audiobookid",
            totalChapters: 10,
            chapters: nil
        )
    )

    fileprivate static let minimalExample = Chapter(
        availableMarkets: nil,
        chapterNumber: 0,
        description: "Desc",
        htmlDescription: "Desc",
        durationMs: 1000,
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
        href: URL(string: "h")!,
        id: "id",
        images: [],
        isPlayable: nil,
        languages: [],
        name: "Name",
        releaseDate: "2023-01-01",
        releaseDatePrecision: "day",
        resumePoint: nil,
        type: .chapter,
        uri: "uri",
        restrictions: nil,
        audiobook: Audiobook(
            authors: [],
            availableMarkets: [],
            copyrights: [],
            description: "D",
            htmlDescription: "D",
            edition: nil,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
            href: URL(string: "h")!,
            id: "aid",
            images: [],
            languages: [],
            mediaType: "audio",
            name: "A",
            narrators: [],
            publisher: "P",
            type: .audiobook,
            uri: "auri",
            totalChapters: 1,
            chapters: nil
        )
    )

    fileprivate static let minimalJSON = """
        {
            "chapter_number": 0,
            "description": "Desc",
            "html_description": "Desc",
            "duration_ms": 1000,
            "explicit": false,
            "external_urls": { "spotify": "u" },
            "href": "h",
            "id": "id",
            "images": [],
            "languages": [],
            "name": "Name",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "chapter",
            "uri": "uri",
            "audiobook": {
                "authors": [],
                "available_markets": [],
                "copyrights": [],
                "description": "D",
                "html_description": "D",
                "explicit": false,
                "external_urls": { "spotify": "u" },
                "href": "h",
                "id": "aid",
                "images": [],
                "languages": [],
                "media_type": "audio",
                "name": "A",
                "narrators": [],
                "publisher": "P",
                "type": "audiobook",
                "uri": "auri",
                "total_chapters": 1
            }
        }
        """
}

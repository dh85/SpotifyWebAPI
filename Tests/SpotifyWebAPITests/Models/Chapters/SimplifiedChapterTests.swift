import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedChapterTests {

    @Test
    func decodesSimplifiedChapterFixture() throws {
        let data = try TestDataLoader.load("chapter_full")
        let chapter: SimplifiedChapter = try decodeModel(from: data)

        #expect(chapter.id == "chapterid")
        #expect(chapter.name == "Chapter 1")
        #expect(chapter.availableMarkets?.contains("US") == true)
        #expect(chapter.resumePoint != nil)
    }
}

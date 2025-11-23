import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct AudiobookTests {

    @Test
    func audiobookDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("audiobook_full.json")
        let audiobook: Audiobook = try decodeModel(from: testData)
        expectAudiobookMatches(audiobook, Audiobook.fullExample)
    }

    @Test
    func audiobookDecodesWithMinimalFields() throws {
        let data = Audiobook.minimalJSON.data(using: .utf8)!
        let audiobook: Audiobook = try decodeModel(from: data)
        expectAudiobookMatches(audiobook, Audiobook.minimalExample)
    }

    private func expectAudiobookMatches(_ actual: Audiobook, _ expected: Audiobook) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.publisher == expected.publisher)
        #expect(actual.mediaType == expected.mediaType)
        #expect(actual.totalChapters == expected.totalChapters)
        #expect(actual.edition == expected.edition)
        #expect(actual.explicit == expected.explicit)
        #expect(actual.authors.count == expected.authors.count)
        #expect(actual.authors.first?.name == expected.authors.first?.name)
        #expect(actual.narrators.count == expected.narrators.count)
        #expect(actual.narrators.first?.name == expected.narrators.first?.name)
        #expect(actual.languages == expected.languages)
        #expect(actual.availableMarkets == expected.availableMarkets)
        #expect(actual.chapters?.total == expected.chapters?.total)
        #expect(actual.chapters?.items.first?.name == expected.chapters?.items.first?.name)
        #expect(actual.externalUrls.spotify == expected.externalUrls.spotify)
        #expect(actual.uri == expected.uri)
    }
}

extension Audiobook {
    fileprivate static let fullExample = Audiobook(
        authors: [Author(name: "Frank Herbert")],
        availableMarkets: ["US", "GB"],
        copyrights: [],
        description: "Description",
        htmlDescription: "HTML Description",
        edition: "Unabridged",
        explicit: false,
        externalUrls: SpotifyExternalUrls(
            spotify: URL(string: "https://open.spotify.com/show/7iHfbu1YPACw6oZPAFJtqe")
        ),
        href: URL(string: "https://api.spotify.com/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe")!,
        id: "7iHfbu1YPACw6oZPAFJtqe",
        images: [],
        languages: ["en"],
        mediaType: "audio",
        name: "Dune: Book One in the Dune Chronicles",
        narrators: [
            Narrator(name: "Scott Brick")
        ],
        publisher: "Macmillan Audio",
        type: .audiobook,
        uri: "spotify:show:7iHfbu1YPACw6oZPAFJtqe",
        totalChapters: 51,
        chapters: Page(
            href: URL(
                string: "https://api.spotify.com/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe/chapters")!,
            items: [],
            limit: 50,
            next: nil,
            offset: 0,
            previous: nil,
            total: 51
        )
    )

    fileprivate static let minimalExample = Audiobook(
        authors: [],
        availableMarkets: [],
        copyrights: [],
        description: "Desc",
        htmlDescription: "Desc",
        edition: nil,
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
        href: URL(string: "h")!,
        id: "id",
        images: [],
        languages: [],
        mediaType: "audio",
        name: "Name",
        narrators: [],
        publisher: "Pub",
        type: .audiobook,
        uri: "uri",
        totalChapters: 5,
        chapters: nil
    )

    fileprivate static let minimalJSON = """
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
}

import Foundation
import Testing

@testable import SpotifyKit

@Suite struct ShowTests {

    @Test
    func showDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("show_full.json")
        let show: Show = try decodeModel(from: testData)
        expectShowMatches(show, Show.fullExample)
    }

    @Test
    func showDecodesWithMinimalFields() throws {
        let data = Show.minimalJSON.data(using: .utf8)!
        let show: Show = try decodeModel(from: data)
        expectShowMatches(show, Show.minimalExample)
    }

    private func expectShowMatches(_ actual: Show, _ expected: Show) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.description == expected.description)
        #expect(actual.htmlDescription == expected.htmlDescription)
        #expect(actual.explicit == expected.explicit)
        #expect(actual.externalUrls?.spotify == expected.externalUrls?.spotify)
        #expect(actual.href == expected.href)
        #expect(actual.images?.count == expected.images?.count)
        #expect(actual.isExternallyHosted == expected.isExternallyHosted)
        #expect(actual.languages == expected.languages)
        #expect(actual.mediaType == expected.mediaType)
        #expect(actual.publisher == expected.publisher)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
        #expect(actual.totalEpisodes == expected.totalEpisodes)
        #expect(actual.copyrights?.count == expected.copyrights?.count)
        #expect(actual.episodes?.items.count == expected.episodes?.items.count)
        #expect(actual.episodes?.total == expected.episodes?.total)
    }
}

extension Show {
    fileprivate static let fullExample = Show(
        availableMarkets: ["US", "CA"],
        copyrights: [SpotifyCopyright(text: "© 2023 Publisher", type: .performance)],
        description: "Show description",
        htmlDescription: "<p>Show description</p>",
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/show/showid")),
        href: URL(string: "https://api.spotify.com/v1/shows/showid")!,
        id: "showid",
        images: [SpotifyImage(url: URL(string: "https://i.scdn.co/image/image1")!, height: 640, width: 640)],
        isExternallyHosted: false,
        languages: ["en"],
        mediaType: "audio",
        name: "Show Name",
        publisher: "Publisher Name",
        type: .show,
        uri: "spotify:show:showid",
        totalEpisodes: 10,
        episodes: Page(
            href: URL(string: "https://api.spotify.com/v1/shows/showid/episodes")!,
            items: [
                SimplifiedEpisode(
                    description: "Episode description",
                    htmlDescription: "<p>Episode description</p>",
                    durationMs: 1800000,
                    explicit: false,
                    externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/episode/ep1")),
                    href: URL(string: "https://api.spotify.com/v1/episodes/ep1")!,
                    id: "ep1",
                    images: [],
                    isExternallyHosted: false,
                    isPlayable: true,
                    languages: ["en"],
                    name: "Episode 1",
                    releaseDate: "2023-01-01",
                    releaseDatePrecision: .day,
                    resumePoint: nil,
                    type: .episode,
                    uri: "spotify:episode:ep1",
                    restrictions: nil
                )
            ],
            limit: 20,
            next: nil,
            offset: 0,
            previous: nil,
            total: 10
        )
    )

    fileprivate static let minimalExample = Show(
        availableMarkets: [],
        copyrights: [],
        description: "D",
        htmlDescription: "D",
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
        href: URL(string: "h")!,
        id: "id",
        images: [],
        isExternallyHosted: false,
        languages: [],
        mediaType: "audio",
        name: "N",
        publisher: "P",
        type: .show,
        uri: "uri",
        totalEpisodes: 0,
        episodes: Page(
            href: URL(string: "h")!,
            items: [],
            limit: 20,
            next: nil,
            offset: 0,
            previous: nil,
            total: 0
        )
    )

    fileprivate static let minimalJSON = """
        {
            "available_markets": [],
            "copyrights": [],
            "description": "D",
            "html_description": "D",
            "explicit": false,
            "external_urls": { "spotify": "u" },
            "href": "h",
            "id": "id",
            "images": [],
            "is_externally_hosted": false,
            "languages": [],
            "media_type": "audio",
            "name": "N",
            "publisher": "P",
            "type": "show",
            "uri": "uri",
            "total_episodes": 0,
            "episodes": {
                "href": "h",
                "items": [],
                "limit": 20,
                "offset": 0,
                "total": 0
            }
        }
        """
}

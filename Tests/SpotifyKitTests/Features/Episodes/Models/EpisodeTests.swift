import Foundation
import Testing

@testable import SpotifyKit

@Suite struct EpisodeTests {

    @Test
    func episodeDecodesCorrectly() throws {
        let testData = try TestDataLoader.load("episode_full.json")
        let episode: Episode = try decodeModel(from: testData)
        expectEpisodeMatches(episode, Episode.fullExample)
    }

    @Test
    func episodeDecodesWithMinimalFields() throws {
        let data = Episode.minimalJSON.data(using: .utf8)!
        let episode: Episode = try decodeModel(from: data)
        expectEpisodeMatches(episode, Episode.minimalExample)
    }

    private func expectEpisodeMatches(_ actual: Episode, _ expected: Episode) {
        #expect(actual.id == expected.id)
        #expect(actual.name == expected.name)
        #expect(actual.description == expected.description)
        #expect(actual.htmlDescription == expected.htmlDescription)
        #expect(actual.durationMs == expected.durationMs)
        #expect(actual.explicit == expected.explicit)
        #expect(actual.externalUrls?.spotify == expected.externalUrls?.spotify)
        #expect(actual.href == expected.href)
        #expect(actual.images?.count == expected.images?.count)
        #expect(actual.isExternallyHosted == expected.isExternallyHosted)
        #expect(actual.isPlayable == expected.isPlayable)
        #expect(actual.languages == expected.languages)
        #expect(actual.releaseDate == expected.releaseDate)
        #expect(actual.releaseDatePrecision == expected.releaseDatePrecision)
        #expect(actual.resumePoint?.fullyPlayed == expected.resumePoint?.fullyPlayed)
        #expect(actual.type == expected.type)
        #expect(actual.uri == expected.uri)
        #expect(actual.restrictions == expected.restrictions)
        #expect(actual.show?.id == expected.show?.id)
    }
}

extension Episode {
    fileprivate static let fullExample = Episode(
        description: "Episode description",
        htmlDescription: "<p>Episode description</p>",
        durationMs: 1800000,
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/episode/episodeid")),
        href: URL(string: "https://api.spotify.com/v1/episodes/episodeid")!,
        id: "episodeid",
        images: [SpotifyImage(url: URL(string: "https://i.scdn.co/image/image1")!, height: 640, width: 640)],
        isExternallyHosted: false,
        isPlayable: true,
        languages: ["en"],
        name: "Episode 1",
        releaseDate: "2023-01-01",
        releaseDatePrecision: .day,
        resumePoint: ResumePoint(fullyPlayed: false, resumePositionMs: 0),
        type: .episode,
        uri: "spotify:episode:episodeid",
        restrictions: nil,
        show: SimplifiedShow(
            availableMarkets: ["US"],
            copyrights: [],
            description: "Show description",
            htmlDescription: "Show description",
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/show/showid")),
            href: URL(string: "https://api.spotify.com/v1/shows/showid")!,
            id: "showid",
            images: [],
            isExternallyHosted: false,
            languages: ["en"],
            mediaType: "audio",
            name: "Show Name",
            publisher: "Publisher",
            type: .show,
            uri: "spotify:show:showid",
            totalEpisodes: 10
        )
    )

    fileprivate static let minimalExample = Episode(
        description: "Desc",
        htmlDescription: "Desc",
        durationMs: 1000,
        explicit: false,
        externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
        href: URL(string: "h")!,
        id: "id",
        images: [],
        isExternallyHosted: false,
        isPlayable: nil,
        languages: [],
        name: "Name",
        releaseDate: "2023-01-01",
        releaseDatePrecision: .day,
        resumePoint: nil,
        type: .episode,
        uri: "uri",
        restrictions: nil,
        show: SimplifiedShow(
            availableMarkets: [],
            copyrights: [],
            description: "D",
            htmlDescription: "D",
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "u")),
            href: URL(string: "h")!,
            id: "sid",
            images: [],
            isExternallyHosted: false,
            languages: [],
            mediaType: "audio",
            name: "S",
            publisher: "P",
            type: .show,
            uri: "suri",
            totalEpisodes: 1
        )
    )

    fileprivate static let minimalJSON = """
        {
            "description": "Desc",
            "html_description": "Desc",
            "duration_ms": 1000,
            "explicit": false,
            "external_urls": { "spotify": "u" },
            "href": "h",
            "id": "id",
            "images": [],
            "is_externally_hosted": false,
            "languages": [],
            "name": "Name",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "episode",
            "uri": "uri",
            "show": {
                "available_markets": [],
                "copyrights": [],
                "description": "D",
                "html_description": "D",
                "explicit": false,
                "external_urls": { "spotify": "u" },
                "href": "h",
                "id": "sid",
                "images": [],
                "is_externally_hosted": false,
                "languages": [],
                "media_type": "audio",
                "name": "S",
                "publisher": "P",
                "type": "show",
                "uri": "suri",
                "total_episodes": 1
            }
        }
        """
}

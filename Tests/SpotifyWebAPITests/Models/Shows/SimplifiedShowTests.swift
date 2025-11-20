import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SimplifiedShowTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "available_markets": ["US", "GB"],
                "copyrights": [
                    {
                        "text": "2024 Publisher",
                        "type": "C"
                    }
                ],
                "description": "A test show",
                "html_description": "<p>A test show</p>",
                "explicit": false,
                "external_urls": {
                    "spotify": "https://open.spotify.com/show/show1"
                },
                "href": "https://api.spotify.com/v1/shows/show1",
                "id": "show1",
                "images": [
                    {
                        "url": "https://i.scdn.co/image/test",
                        "height": 640,
                        "width": 640
                    }
                ],
                "is_externally_hosted": false,
                "languages": ["en"],
                "media_type": "audio",
                "name": "Test Show",
                "publisher": "Test Publisher",
                "type": "show",
                "uri": "spotify:show:show1",
                "total_episodes": 10
            }
            """
        let data = json.data(using: .utf8)!
        let show: SimplifiedShow = try decodeModel(from: data)

        #expect(show.availableMarkets == ["US", "GB"])
        #expect(show.copyrights?.count == 1)
        #expect(show.description == "A test show")
        #expect(show.htmlDescription == "<p>A test show</p>")
        #expect(show.explicit == false)
        #expect(show.id == "show1")
        #expect(show.images.count == 1)
        #expect(show.isExternallyHosted == false)
        #expect(show.languages == ["en"])
        #expect(show.mediaType == "audio")
        #expect(show.name == "Test Show")
        #expect(show.publisher == "Test Publisher")
        #expect(show.type == .show)
        #expect(show.totalEpisodes == 10)
    }

    @Test
    func decodesWithoutOptionalFields() throws {
        let json = """
            {
                "description": "A test show",
                "explicit": false,
                "external_urls": {},
                "href": "https://api.spotify.com/v1/shows/show2",
                "id": "show2",
                "images": [],
                "is_externally_hosted": false,
                "languages": ["en"],
                "media_type": "audio",
                "name": "Test Show",
                "publisher": "Publisher",
                "type": "show",
                "uri": "spotify:show:show2",
                "total_episodes": 5
            }
            """
        let data = json.data(using: .utf8)!
        let show: SimplifiedShow = try decodeModel(from: data)

        #expect(show.availableMarkets == nil)
        #expect(show.copyrights == nil)
        #expect(show.htmlDescription == nil)
        #expect(show.id == "show2")
        #expect(show.totalEpisodes == 5)
    }

    @Test
    func equatableWorksCorrectly() {
        let show1 = SimplifiedShow(
            availableMarkets: ["US"],
            copyrights: [],
            description: "Test",
            htmlDescription: nil,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/shows/s1")!,
            id: "s1",
            images: [],
            isExternallyHosted: false,
            languages: ["en"],
            mediaType: "audio",
            name: "Show",
            publisher: "Pub",
            type: .show,
            uri: "spotify:show:s1",
            totalEpisodes: 1
        )
        let show2 = SimplifiedShow(
            availableMarkets: ["US"],
            copyrights: [],
            description: "Test",
            htmlDescription: nil,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/shows/s1")!,
            id: "s1",
            images: [],
            isExternallyHosted: false,
            languages: ["en"],
            mediaType: "audio",
            name: "Show",
            publisher: "Pub",
            type: .show,
            uri: "spotify:show:s1",
            totalEpisodes: 1
        )
        let show3 = SimplifiedShow(
            availableMarkets: ["US"],
            copyrights: [],
            description: "Test",
            htmlDescription: nil,
            explicit: false,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            href: URL(string: "https://api.spotify.com/v1/shows/s2")!,
            id: "s2",
            images: [],
            isExternallyHosted: false,
            languages: ["en"],
            mediaType: "audio",
            name: "Show",
            publisher: "Pub",
            type: .show,
            uri: "spotify:show:s2",
            totalEpisodes: 1
        )

        #expect(show1 == show2)
        #expect(show1 != show3)
    }
}

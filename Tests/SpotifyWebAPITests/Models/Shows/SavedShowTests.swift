import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SavedShowTests {

    @Test
    func decodesWithAddedAtField() throws {
        let json = """
            {
                "added_at": "2024-01-15T10:30:00Z",
                "show": {
                    "id": "show123",
                    "name": "Test Show",
                    "description": "A test show",
                    "html_description": "<p>A test show</p>",
                    "explicit": false,
                    "href": "https://api.spotify.com/v1/shows/show123",
                    "uri": "spotify:show:show123",
                    "type": "show",
                    "external_urls": {},
                    "images": [],
                    "is_externally_hosted": false,
                    "languages": ["en"],
                    "media_type": "audio",
                    "publisher": "Test Publisher",
                    "available_markets": [],
                    "copyrights": [],
                    "total_episodes": 10
                }
            }
            """
        let data = json.data(using: .utf8)!
        let savedShow: SavedShow = try decodeModel(from: data)

        #expect(savedShow.addedAt.timeIntervalSince1970 == 1_705_314_600)
        #expect(savedShow.show.id == "show123")
        #expect(savedShow.show.name == "Test Show")
    }

    @Test
    func encodesCorrectly() throws {
        let show = SimplifiedShow(
            availableMarkets: [],
            copyrights: [],
            description: "Test",
            htmlDescription: "Test",
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
        let savedShow = SavedShow(
            addedAt: Date(timeIntervalSince1970: 1_700_000_000),
            show: show
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(savedShow)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded: SavedShow = try decoder.decode(SavedShow.self, from: data)

        #expect(decoded.addedAt.timeIntervalSince1970 == savedShow.addedAt.timeIntervalSince1970)
        #expect(decoded.show == savedShow.show)
    }

    @Test
    func equatableWorksCorrectly() throws {
        let show = SimplifiedShow(
            availableMarkets: [],
            copyrights: [],
            description: "Test",
            htmlDescription: "Test",
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
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let savedShow1 = SavedShow(addedAt: date, show: show)
        let savedShow2 = SavedShow(addedAt: date, show: show)
        let savedShow3 = SavedShow(addedAt: Date(timeIntervalSince1970: 1_600_000_000), show: show)

        #expect(savedShow1 == savedShow2)
        #expect(savedShow1 != savedShow3)
    }
}

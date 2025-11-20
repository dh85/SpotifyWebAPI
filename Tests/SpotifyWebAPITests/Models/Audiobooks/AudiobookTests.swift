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
        availableMarkets: [
            "AR", "AU", "AT", "BE", "BO", "BR", "BG", "CA", "CL", "CO", "CR", "CY", "CZ", "DK",
            "DO", "DE", "EC", "EE", "SV", "FI", "FR", "GR", "GT", "HN", "HK", "HU", "IS", "IE",
            "IT", "LV", "LT", "LU", "MY", "MT", "MX", "NL", "NZ", "NI", "NO", "PA", "PY", "PE",
            "PH", "PL", "PT", "SG", "SK", "ES", "SE", "CH", "TW", "TR", "UY", "US", "GB", "AD",
            "LI", "MC", "ID", "JP", "TH", "VN", "RO", "IL", "ZA", "SA", "AE", "BH", "QA", "OM",
            "KW", "EG", "MA", "DZ", "TN", "LB", "JO", "PS", "IN", "BY", "KZ", "MD", "UA", "AL",
            "BA", "HR", "ME", "MK", "RS", "SI", "KR", "BD", "PK", "LK", "GH", "KE", "NG", "TZ",
            "UG", "AG", "AM", "BS", "BB", "BZ", "BT", "BW", "BF", "CV", "CW", "DM", "FJ", "GM",
            "GE", "GD", "GW", "GY", "HT", "JM", "KI", "LS", "LR", "MW", "MV", "ML", "MH", "FM",
            "NA", "NR", "NE", "PW", "PG", "PR", "WS", "SM", "ST", "SN", "SC", "SL", "SB", "KN",
            "LC", "VC", "SR", "TL", "TO", "TT", "TV", "VU", "AZ", "BN", "BI", "KH", "CM", "TD",
            "KM", "GQ", "SZ", "GA", "GN", "KG", "LA", "MO", "MR", "MN", "NP", "RW", "TG", "UZ",
            "ZW", "BJ", "MG", "MU", "MZ", "AO", "CI", "DJ", "ZM", "CD", "CG", "IQ", "LY", "TJ",
            "VE", "ET", "XK",
        ],
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
            Narrator(name: "Scott Brick"), Narrator(name: "Other"), Narrator(name: "Other"),
            Narrator(name: "Other"), Narrator(name: "Other"),
        ],
        publisher: "Frank Herbert",
        type: .audiobook,
        uri: "spotify:show:7iHfbu1YPACw6oZPAFJtqe",
        totalChapters: 51,
        chapters: Page(
            href: URL(
                string: "https://api.spotify.com/v1/audiobooks/7iHfbu1YPACw6oZPAFJtqe/chapters")!,
            items: [
                SimplifiedChapter(
                    availableMarkets: [
                        "AR", "AU", "AT", "BE", "BO", "BR", "BG", "CA", "CL", "CO", "CR", "CY",
                        "CZ", "DK", "DO", "DE", "EC", "EE", "SV", "FI", "FR", "GR", "GT", "HN",
                        "HK", "HU", "IS", "IE", "IT", "LV", "LT", "LU", "MY", "MT", "MX", "NL",
                        "NZ", "NI", "NO", "PA", "PY", "PE", "PH", "PL", "PT", "SG", "SK", "ES",
                        "SE", "CH", "TW", "TR", "UY", "US", "GB", "AD", "LI", "MC", "ID", "JP",
                        "TH", "VN", "RO", "IL", "ZA", "SA", "AE", "BH", "QA", "OM", "KW", "EG",
                        "MA", "DZ", "TN", "LB", "JO", "PS", "IN", "BY", "KZ", "MD", "UA", "AL",
                        "BA", "HR", "ME", "MK", "RS", "SI", "KR", "BD", "PK", "LK", "GH", "KE",
                        "NG", "TZ", "UG", "AG", "AM", "BS", "BB", "BZ", "BT", "BW", "BF", "CV",
                        "CW", "DM", "FJ", "GM", "GE", "GD", "GW", "GY", "HT", "JM", "KI", "LS",
                        "LR", "MW", "MV", "ML", "MH", "FM", "NA", "NR", "NE", "PW", "PG", "PR",
                        "WS", "SM", "ST", "SN", "SC", "SL", "SB", "KN", "LC", "VC", "SR", "TL",
                        "TO", "TT", "TV", "VU", "AZ", "BN", "BI", "KH", "CM", "TD", "KM", "GQ",
                        "SZ", "GA", "GN", "KG", "LA", "MO", "MR", "MN", "NP", "RW", "TG", "UZ",
                        "ZW", "BJ", "MG", "MU", "MZ", "AO", "CI", "DJ", "ZM", "CD", "CG", "IQ",
                        "LY", "TJ", "VE", "ET", "XK",
                    ],
                    chapterNumber: 0,
                    description: "",
                    htmlDescription: "",
                    durationMs: 60056,
                    explicit: false,
                    externalUrls: SpotifyExternalUrls(
                        spotify: URL(
                            string: "https://open.spotify.com/episode/73ThiUvDp7VbVX6tWTNjE4")),
                    href: URL(
                        string: "https://api.spotify.com/v1/chapters/73ThiUvDp7VbVX6tWTNjE4")!,
                    id: "73ThiUvDp7VbVX6tWTNjE4",
                    images: [
                        SpotifyImage(
                            url: URL(
                                string:
                                    "https://i.scdn.co/image/ab676663000022a8706d7d39148810e742cef314"
                            )!, height: 640, width: 640),
                        SpotifyImage(
                            url: URL(
                                string:
                                    "https://i.scdn.co/image/ab6766630000db5b706d7d39148810e742cef314"
                            )!, height: 300, width: 300),
                        SpotifyImage(
                            url: URL(
                                string:
                                    "https://i.scdn.co/image/ab6766630000703b706d7d39148810e742cef314"
                            )!, height: 64, width: 64),
                    ],
                    isPlayable: nil,
                    languages: [""],
                    name: "Opening Credits",
                    releaseDate: "2007-05-29",
                    releaseDatePrecision: .day,
                    resumePoint: ResumePoint(fullyPlayed: false, resumePositionMs: 0),
                    type: .chapter,
                    uri: "spotify:episode:73ThiUvDp7VbVX6tWTNjE4",
                    restrictions: nil,
                    audioPreviewUrl: nil
                )
            ],
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

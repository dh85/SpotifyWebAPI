import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PageTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "href": "https://api.spotify.com/v1/albums?offset=0&limit=2",
                "items": ["item1", "item2"],
                "limit": 2,
                "next": "https://api.spotify.com/v1/albums?offset=2&limit=2",
                "offset": 0,
                "previous": null,
                "total": 10
            }
            """
        let data = json.data(using: .utf8)!
        let page: Page<String> = try decodeModel(from: data)

        #expect(page.href.absoluteString == "https://api.spotify.com/v1/albums?offset=0&limit=2")
        #expect(page.items == ["item1", "item2"])
        #expect(page.limit == 2)
        #expect(page.next?.absoluteString == "https://api.spotify.com/v1/albums?offset=2&limit=2")
        #expect(page.offset == 0)
        #expect(page.previous == nil)
        #expect(page.total == 10)
    }

    @Test
    func decodesWithEmptyItems() throws {
        let json = """
            {
                "href": "https://api.spotify.com/v1/albums?offset=0&limit=2",
                "items": [],
                "limit": 2,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": 0
            }
            """
        let data = json.data(using: .utf8)!
        let page: Page<String> = try decodeModel(from: data)

        #expect(page.items.isEmpty)
        #expect(page.next == nil)
        #expect(page.previous == nil)
        #expect(page.total == 0)
    }

    @Test
    func decodesWithPreviousPage() throws {
        let json = """
            {
                "href": "https://api.spotify.com/v1/albums?offset=2&limit=2",
                "items": ["item3"],
                "limit": 2,
                "next": null,
                "offset": 2,
                "previous": "https://api.spotify.com/v1/albums?offset=0&limit=2",
                "total": 3
            }
            """
        let data = json.data(using: .utf8)!
        let page: Page<String> = try decodeModel(from: data)

        #expect(page.offset == 2)
        #expect(page.next == nil)
        #expect(
            page.previous?.absoluteString == "https://api.spotify.com/v1/albums?offset=0&limit=2")
    }

    @Test
    func equatableWorksCorrectly() throws {
        let page1 = Page(
            href: URL(string: "https://api.spotify.com/v1/test")!,
            items: ["a", "b"],
            limit: 2,
            next: nil,
            offset: 0,
            previous: nil,
            total: 2
        )
        let page2 = Page(
            href: URL(string: "https://api.spotify.com/v1/test")!,
            items: ["a", "b"],
            limit: 2,
            next: nil,
            offset: 0,
            previous: nil,
            total: 2
        )
        let page3 = Page(
            href: URL(string: "https://api.spotify.com/v1/test")!,
            items: ["c"],
            limit: 2,
            next: nil,
            offset: 0,
            previous: nil,
            total: 1
        )

        #expect(page1 == page2)
        #expect(page1 != page3)
    }

    @Test
    func encodesCorrectly() throws {
        let page = Page(
            href: URL(string: "https://api.spotify.com/v1/test")!,
            items: ["item1"],
            limit: 1,
            next: URL(string: "https://api.spotify.com/v1/test?offset=1"),
            offset: 0,
            previous: nil,
            total: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(page)
        let decoded: Page<String> = try JSONDecoder().decode(Page.self, from: data)

        #expect(decoded == page)
    }
}

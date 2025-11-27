import Foundation
import Testing

@testable import SpotifyKit

@Suite struct PagingStreamsTests {

    @Test
    func paginationStreamBuilderEmitsPages() async throws {
        var yielded: [[Int]] = []

        let stream = PaginationStreamBuilder.pages(pageSize: 2) { limit, offset in
            let start = offset
            let end = min(offset + limit, 5)
            let items = Array(start..<end)
            let next =
                end < 5
                ? URL(string: "https://example.com?offset=\(end)") : nil
            return Page(
                href: URL(string: "https://example.com")!,
                items: items,
                limit: limit,
                next: next,
                offset: offset,
                previous: nil,
                total: 5
            )
        }

        for try await page in stream {
            yielded.append(page.items)
        }

        #expect(yielded == [[0, 1], [2, 3], [4]])
    }

    @Test
    func paginationStreamBuilderEmitsItems() async throws {
        var items: [Int] = []

        let stream = PaginationStreamBuilder.items(pageSize: 2, maxItems: 3) { limit, offset in
            let start = offset
            let end = min(offset + limit, 5)
            let slice = Array(start..<end)
            let next =
                end < 5
                ? URL(string: "https://example.com?offset=\(end)") : nil
            return Page(
                href: URL(string: "https://example.com")!,
                items: slice,
                limit: limit,
                next: next,
                offset: offset,
                previous: nil,
                total: 5
            )
        }

        for try await value in stream {
            items.append(value)
        }

        #expect(items == [0, 1, 2])
    }

    @Test
    func streamPagesYieldsAllPages() async throws {
        let (client, _) = await makeUserAuthClient()

        var pages: [Page<String>] = []

        for try await page in client.streamPages(
            pageSize: 2,
            fetchPage: { limit, offset in
                // Simulate 3 pages
                let items: [String]
                let hasNext: Bool

                switch offset {
                case 0:
                    items = ["A", "B"]
                    hasNext = true
                case 2:
                    items = ["C", "D"]
                    hasNext = true
                case 4:
                    items = ["E"]
                    hasNext = false
                default:
                    items = []
                    hasNext = false
                }

                return Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: items,
                    limit: limit,
                    next: hasNext
                        ? URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)")
                        : nil,
                    offset: offset,
                    previous: nil,
                    total: 5
                )
            })
        {
            pages.append(page)
        }

        #expect(pages.count == 3)
        #expect(pages[0].items == ["A", "B"])
        #expect(pages[1].items == ["C", "D"])
        #expect(pages[2].items == ["E"])
    }

    @Test
    func allItemsProviderStreamsPages() async throws {
        let (client, _) = await makeUserAuthClient()

        let provider = client.makeAllItemsProvider(pageSize: 2) { limit, offset in
            let range = Array(offset..<(offset + limit))
            let hasNext = offset + limit < 6
            return Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: range,
                limit: limit,
                next: hasNext
                    ? URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)") : nil,
                offset: offset,
                previous: nil,
                total: 6
            )
        }

        var seen = 0
        for try await page in provider.streamPages(maxPages: 2) {
            seen += page.items.count
        }

        #expect(seen == 4)
    }

    @Test
    func streamPagesRespectsMaxPages() async throws {
        let (client, _) = await makeUserAuthClient()

        var pageCount = 0

        for try await _ in client.streamPages(
            pageSize: 2, maxPages: 2,
            fetchPage: { limit, offset in
                Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: ["A", "B"],
                    limit: limit,
                    next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                    offset: offset,
                    previous: nil,
                    total: 100
                )
            })
        {
            pageCount += 1
        }

        #expect(pageCount == 2)
    }

    @Test
    func streamItemsYieldsAllItems() async throws {
        let (client, _) = await makeUserAuthClient()

        var items: [String] = []

        for try await item in client.streamItems(
            pageSize: 2,
            fetchPage: { limit, offset in
                let pageItems: [String]
                let hasNext: Bool

                switch offset {
                case 0:
                    pageItems = ["A", "B"]
                    hasNext = true
                case 2:
                    pageItems = ["C", "D"]
                    hasNext = true
                case 4:
                    pageItems = ["E"]
                    hasNext = false
                default:
                    pageItems = []
                    hasNext = false
                }

                return Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: pageItems,
                    limit: limit,
                    next: hasNext
                        ? URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)")
                        : nil,
                    offset: offset,
                    previous: nil,
                    total: 5
                )
            })
        {
            items.append(item)
        }

        #expect(items == ["A", "B", "C", "D", "E"])
    }

    @Test
    func streamItemsRespectsMaxItems() async throws {
        let (client, _) = await makeUserAuthClient()

        var items: [String] = []

        for try await item in client.streamItems(
            pageSize: 2, maxItems: 3,
            fetchPage: { limit, offset in
                Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: ["A", "B"],
                    limit: limit,
                    next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                    offset: offset,
                    previous: nil,
                    total: 100
                )
            })
        {
            items.append(item)
        }

        #expect(items.count == 3)
        #expect(items == ["A", "B", "A"])
    }

    @Test
    func streamPagesSupportsCancellation() async throws {
        let (client, _) = await makeUserAuthClient()

        let task = Task {
            var pageCount = 0

            for try await _ in client.streamPages(
                pageSize: 2,
                fetchPage: { limit, offset in
                    try await Task.sleep(for: .milliseconds(50))
                    return Page(
                        href: URL(string: "https://api.spotify.com/v1/test")!,
                        items: ["A", "B"],
                        limit: limit,
                        next: URL(
                            string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                        offset: offset,
                        previous: nil,
                        total: 1000
                    )
                })
            {
                pageCount += 1
            }

            return pageCount
        }

        // Cancel after a short delay
        try await Task.sleep(for: .milliseconds(10))
        task.cancel()

        let result = await task.result

        // Task should either be cancelled or fetch very few pages
        switch result {
        case .success(let count):
            #expect(count < 5)  // Should stop early
        case .failure:
            // Cancellation is also acceptable
            break
        }
    }

    @Test
    func streamItemsSupportsCancellation() async throws {
        let (client, _) = await makeUserAuthClient()

        let task = Task<Int, Error> {
            var consumed = 0

            for try await _ in client.streamItems(
                pageSize: 2,
                fetchPage: { limit, offset in
                    try await Task.sleep(for: .milliseconds(50))
                    return Page(
                        href: URL(string: "https://api.spotify.com/v1/test")!,
                        items: ["item"],
                        limit: limit,
                        next: URL(
                            string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                        offset: offset,
                        previous: nil,
                        total: 1000
                    )
                })
            {
                consumed += 1
            }

            return consumed
        }

        try await Task.sleep(for: .milliseconds(10))
        task.cancel()

        let result = await task.result
        switch result {
        case .success(let value):
            #expect(value < 5)
        case .failure:
            break
        }
    }
}

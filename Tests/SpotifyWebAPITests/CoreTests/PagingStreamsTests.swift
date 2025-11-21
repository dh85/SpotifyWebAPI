import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PagingStreamsTests {

    @Test
    func streamPagesYieldsAllPages() async throws {
        let (client, _) = await makeUserAuthClient()
        
        var pages: [Page<String>] = []
        
        for try await page in client.streamPages(pageSize: 2) { limit, offset -> Page<String> in
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
                next: hasNext ? URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)") : nil,
                offset: offset,
                previous: nil,
                total: 5
            )
        } {
            pages.append(page)
        }
        
        #expect(pages.count == 3)
        #expect(pages[0].items == ["A", "B"])
        #expect(pages[1].items == ["C", "D"])
        #expect(pages[2].items == ["E"])
    }

    @Test
    func streamPagesRespectsMaxPages() async throws {
        let (client, _) = await makeUserAuthClient()
        
        var pageCount = 0
        
        for try await _ in client.streamPages(pageSize: 2, maxPages: 2) { limit, offset -> Page<String> in
            Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: ["A", "B"],
                limit: limit,
                next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                offset: offset,
                previous: nil,
                total: 100
            )
        } {
            pageCount += 1
        }
        
        #expect(pageCount == 2)
    }

    @Test
    func streamItemsYieldsAllItems() async throws {
        let (client, _) = await makeUserAuthClient()
        
        var items: [String] = []
        
        for try await item in client.streamItems(pageSize: 2) { limit, offset -> Page<String> in
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
                next: hasNext ? URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)") : nil,
                offset: offset,
                previous: nil,
                total: 5
            )
        } {
            items.append(item)
        }
        
        #expect(items == ["A", "B", "C", "D", "E"])
    }

    @Test
    func streamItemsRespectsMaxItems() async throws {
        let (client, _) = await makeUserAuthClient()
        
        var items: [String] = []
        
        for try await item in client.streamItems(pageSize: 2, maxItems: 3) { limit, offset -> Page<String> in
            Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: ["A", "B"],
                limit: limit,
                next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                offset: offset,
                previous: nil,
                total: 100
            )
        } {
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
            
            for try await _ in client.streamPages(pageSize: 2) { limit, offset -> Page<String> in
                try await Task.sleep(for: .milliseconds(50))
                return Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: ["A", "B"],
                    limit: limit,
                    next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                    offset: offset,
                    previous: nil,
                    total: 1000
                )
            } {
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
}

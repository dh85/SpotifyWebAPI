import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct PagingHelpersTests {

    @Test
    func collectAllPagesGathersAllItems() async throws {
        let (client, _) = await makeUserAuthClient()
        
        let allItems = try await client.collectAllPages(
            pageSize: 2,
            maxItems: nil
        ) { limit, offset -> Page<String> in
            // Simulate 3 pages: [A,B], [C,D], [E]
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
        }
        
        #expect(allItems == ["A", "B", "C", "D", "E"])
    }

    @Test
    func collectAllPagesRespectsMaxItems() async throws {
        let (client, _) = await makeUserAuthClient()
        
        let allItems = try await client.collectAllPages(
            pageSize: 2,
            maxItems: 3
        ) { limit, offset -> Page<String> in
            let items = ["A", "B", "C", "D", "E"]
            let start = offset
            let end = min(start + limit, items.count)
            
            return Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: Array(items[start..<end]),
                limit: limit,
                next: end < items.count ? URL(string: "https://api.spotify.com/v1/test?offset=\(end)") : nil,
                offset: offset,
                previous: nil,
                total: items.count
            )
        }
        
        #expect(allItems.count == 3)
        #expect(allItems == ["A", "B", "C"])
    }

    @Test
    func collectAllPagesStopsWhenNextIsNil() async throws {
        let (client, _) = await makeUserAuthClient()
        
        let allItems = try await client.collectAllPages(
            pageSize: 10,
            maxItems: nil
        ) { limit, offset -> Page<String> in
            return Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: ["A", "B"],
                limit: limit,
                next: nil,  // No more pages
                offset: offset,
                previous: nil,
                total: 2
            )
        }
        
        #expect(allItems == ["A", "B"])
    }

    @Test
    func collectAllPagesClampsPageSize() async throws {
        let (client, _) = await makeUserAuthClient()
        
        let result = try await client.collectAllPages(
            pageSize: 100,  // Too large
            maxItems: nil
        ) { limit, offset -> Page<Int> in
            // Return limit as item to verify it was clamped
            return Page(
                href: URL(string: "https://api.spotify.com/v1/test")!,
                items: [limit],
                limit: limit,
                next: nil,
                offset: offset,
                previous: nil,
                total: 1
            )
        }
        
        #expect(result.first == 50)  // Clamped to max
    }

    @Test
    func collectAllPagesHonorsCancellationBetweenPages() async throws {
        let (client, _) = await makeUserAuthClient()
        let recorder = FetchRecorder()

        let collectingTask = Task {
            try await client.collectAllPages(
                pageSize: 2,
                maxItems: nil
            ) { limit, offset -> Page<String> in
                await recorder.record(offset: offset)

                return Page(
                    href: URL(string: "https://api.spotify.com/v1/test")!,
                    items: ["item-\(offset)"],
                    limit: limit,
                    next: URL(string: "https://api.spotify.com/v1/test?offset=\(offset + limit)"),
                    offset: offset,
                    previous: nil,
                    total: 10
                )
            }
        }

        // Wait until the first fetch occurs
        while await recorder.count == 0 {
            await Task.yield()
        }

        collectingTask.cancel()

        do {
            _ = try await collectingTask.value
            Issue.record("Expected collectAllPages to be cancelled")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }

        let fetchCount = await recorder.count
        #expect(fetchCount == 1)
    }
}

private actor FetchRecorder {
    private(set) var count: Int = 0

    func record(offset: Int) {
        _ = offset
        count += 1
    }
}

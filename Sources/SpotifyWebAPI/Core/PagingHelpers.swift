extension SpotifyClient {
    /// Internal helper to gather all pages for endpoints returning `Page<T>`.
    func collectAllPages<T>(
        pageSize: Int,
        maxItems: Int?,
        fetchPage: @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<T>
    ) async throws -> [T] {
        var all: [T] = []
        let clampedPageSize = min(max(pageSize, 1), 50)
        var offset = 0

        while true {
            let page = try await fetchPage(clampedPageSize, offset)
            all.append(contentsOf: page.items)

            if let maxItems, all.count >= maxItems {
                return Array(all.prefix(maxItems))
            }

            if page.next == nil || all.count >= page.total {
                break
            }

            offset += page.limit
        }

        return all
    }
}

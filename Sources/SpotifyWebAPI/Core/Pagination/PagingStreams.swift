import Foundation

extension SpotifyClient {
    /// Streams pages from a paginated endpoint.
    ///
    /// Returns an `AsyncStream` that yields pages as they're fetched, allowing for:
    /// - Incremental processing without loading everything into memory
    /// - Automatic cancellation support
    /// - Progress tracking (each page is a progress update)
    ///
    /// ## Example: Stream All Saved Tracks
    /// ```swift
    /// for await page in client.streamPages(pageSize: 50) { limit, offset in
    ///     try await client.tracks.saved(limit: limit, offset: offset)
    /// } {
    ///     print("Fetched \(page.items.count) tracks")
    ///     processTracks(page.items)
    /// }
    /// ```
    ///
    /// ## Example: With Progress
    /// ```swift
    /// var totalFetched = 0
    /// for await page in client.streamPages(pageSize: 50) { limit, offset in
    ///     try await client.tracks.saved(limit: limit, offset: offset)
    /// } {
    ///     totalFetched += page.items.count
    ///     let progress = Double(totalFetched) / Double(page.total)
    ///     updateProgress(progress)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - pageSize: Number of items per request (clamped to 1-50).
    ///   - maxPages: Optional limit on number of pages to fetch.
    ///   - fetchPage: Closure that fetches a single page given limit and offset.
    /// - Returns: AsyncStream that yields pages as they're fetched.
    nonisolated public func streamPages<T>(
        pageSize: Int = 50,
        maxPages: Int? = nil,
        fetchPage: @escaping @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<T>
    ) -> AsyncThrowingStream<Page<T>, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let clampedPageSize = min(max(pageSize, 1), 50)
                var offset = 0
                var pageCount = 0
                
                do {
                    while true {
                        // Check for cancellation
                        try Task.checkCancellation()
                        
                        // Fetch page
                        let page = try await fetchPage(clampedPageSize, offset)
                        
                        // Yield page to consumer
                        continuation.yield(page)
                        
                        pageCount += 1
                        
                        // Check if we should stop
                        if let maxPages, pageCount >= maxPages {
                            break
                        }
                        
                        if page.next == nil {
                            break
                        }
                        
                        offset += page.limit
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    /// Streams individual items from a paginated endpoint.
    ///
    /// Returns an `AsyncStream` that yields items one at a time, fetching pages as needed.
    /// More memory efficient than `streamPages` when you only need to process items individually.
    ///
    /// ## Example: Process Each Track
    /// ```swift
    /// for try await track in client.streamItems(pageSize: 50) { limit, offset in
    ///     try await client.tracks.saved(limit: limit, offset: offset)
    /// } {
    ///     await processTrack(track)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - pageSize: Number of items per request (clamped to 1-50).
    ///   - maxItems: Optional limit on total items to stream.
    ///   - fetchPage: Closure that fetches a single page given limit and offset.
    /// - Returns: AsyncStream that yields items one at a time.
    nonisolated public func streamItems<T>(
        pageSize: Int = 50,
        maxItems: Int? = nil,
        fetchPage: @escaping @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<T>
    ) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let clampedPageSize = min(max(pageSize, 1), 50)
                var offset = 0
                var itemCount = 0
                
                do {
                    while true {
                        try Task.checkCancellation()
                        
                        let page = try await fetchPage(clampedPageSize, offset)
                        
                        // Yield each item individually
                        for item in page.items {
                            continuation.yield(item)
                            itemCount += 1
                            
                            if let maxItems, itemCount >= maxItems {
                                continuation.finish()
                                return
                            }
                        }
                        
                        if page.next == nil {
                            break
                        }
                        
                        offset += page.limit
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

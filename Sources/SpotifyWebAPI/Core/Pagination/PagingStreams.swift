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
    /// ## Example: Cancel From UI
    /// ```swift
    /// let task = Task {
    ///     for try await page in client.streamPages(pageSize: 50) { limit, offset in
    ///         try await client.tracks.saved(limit: limit, offset: offset)
    ///     } {
    ///         render(page.items)
    ///     }
    /// }
    /// cancelButton.onTap { task.cancel() }
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
        PaginationStreamBuilder.pages(
            pageSize: pageSize,
            maxPages: maxPages,
            fetchPage: fetchPage
        )
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
    /// ## Example: Early Exit With Cancellation
    /// ```swift
    /// let task = Task {
    ///     for try await track in client.streamItems(maxItems: 250) { limit, offset in
    ///         try await client.tracks.saved(limit: limit, offset: offset)
    ///     } {
    ///         try await store(track)
    ///     }
    /// }
    /// Task.detached {
    ///     try await Task.sleep(for: .seconds(1))
    ///     task.cancel()
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
        PaginationStreamBuilder.items(
            pageSize: pageSize,
            maxItems: maxItems,
            fetchPage: fetchPage
        )
    }
}

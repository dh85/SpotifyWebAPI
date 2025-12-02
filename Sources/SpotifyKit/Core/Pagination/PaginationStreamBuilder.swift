import Foundation

/// Utilities for building cancellable async sequences over paginated Spotify endpoints.
public enum PaginationStreamBuilder {
  /// Creates an async sequence that yields entire `Page` values while handling cancellation.
  ///
  /// Example usage:
  /// ```swift
  /// let stream = PaginationStreamBuilder.pages(pageSize: 50) { limit, offset in
  ///     try await client.tracks.saved(limit: limit, offset: offset)
  /// }
  ///
  /// let task = Task {
  ///     for try await page in stream {
  ///         render(page.items)
  ///     }
  /// }
  ///
  /// // Cancel from UI interaction
  /// cancelButton.onTap { task.cancel() }
  /// ```
  ///
  /// - Parameters:
  ///   - pageSize: Desired number of items per request. Automatically clamped to 1...50.
  ///   - maxPages: Optional upper bound on the number of pages to fetch.
  ///   - fetchPage: Closure that returns a `Page` for the supplied limit + offset.
  public static func pages<T>(
    pageSize: Int = 50,
    maxPages: Int? = nil,
    fetchPage: @escaping @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<T>
  ) -> AsyncThrowingStream<Page<T>, Error> {
    makeStream { continuation in
      let clampedPageSize = min(max(pageSize, 1), 50)
      var offset = 0
      var pageCount = 0

      while true {
        try Task.checkCancellation()
        let page = try await fetchPage(clampedPageSize, offset)
        continuation.yield(page)

        pageCount += 1
        if let maxPages, pageCount >= maxPages { break }
        if page.next == nil { break }

        offset += page.limit
      }

      continuation.finish()
    }
  }

  /// Creates an async sequence that yields individual items while lazily fetching pages.
  ///
  /// Example usage:
  /// ```swift
  /// let stream = PaginationStreamBuilder.items(pageSize: 20) { limit, offset in
  ///     try await client.tracks.saved(limit: limit, offset: offset)
  /// }
  ///
  /// let task = Task {
  ///     for try await track in stream {
  ///         try await process(track)
  ///     }
  /// }
  ///
  /// // Later, cancel if the user navigates away.
  /// task.cancel()
  /// ```
  ///
  /// - Parameters:
  ///   - pageSize: Desired number of items per request. Automatically clamped to 1...50.
  ///   - maxItems: Optional upper bound on the total number of items to emit.
  ///   - fetchPage: Closure that returns a `Page` for the supplied limit + offset.
  public static func items<T>(
    pageSize: Int = 50,
    maxItems: Int? = nil,
    fetchPage: @escaping @Sendable (_ limit: Int, _ offset: Int) async throws -> Page<T>
  ) -> AsyncThrowingStream<T, Error> {
    makeStream { continuation in
      let clampedPageSize = min(max(pageSize, 1), 50)
      var offset = 0
      var emitted = 0

      while true {
        try Task.checkCancellation()
        let page = try await fetchPage(clampedPageSize, offset)

        for item in page.items {
          continuation.yield(item)
          emitted += 1

          if let maxItems, emitted >= maxItems {
            continuation.finish()
            return
          }
        }

        if page.next == nil { break }
        offset += page.limit
      }

      continuation.finish()
    }
  }
}

extension PaginationStreamBuilder {
  fileprivate static func makeStream<Element>(
    _ body:
      @escaping @Sendable (AsyncThrowingStream<Element, Error>.Continuation) async throws ->
      Void
  ) -> AsyncThrowingStream<Element, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          try await body(continuation)
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

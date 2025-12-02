extension SpotifyClient {
  /// Collects all pages from a paginated endpoint.
  ///
  /// Automatically fetches subsequent pages until all items are retrieved or `maxItems` is reached.
  /// Requests are made sequentially to respect Spotify's rate limits.
  ///
  /// - Warning: For large collections (10,000+ items), this can take 20+ seconds and may hit rate limits.
  ///   Consider using `maxItems` to limit the fetch, or implement manual pagination for better UX.
  ///
  /// ## Handling Large Collections (10,000+ items)
  ///
  /// For very large collections, implement manual pagination with progress feedback:
  ///
  /// ```swift
  /// var allTracks: [SavedTrack] = []
  /// var offset = 0
  /// let limit = 50
  ///
  /// while true {
  ///     let page = try await client.tracks.saved(limit: limit, offset: offset)
  ///     allTracks.append(contentsOf: page.items)
  ///
  ///     // Update progress UI
  ///     let progress = Double(allTracks.count) / Double(page.total)
  ///     updateProgress(progress)
  ///
  ///     // Check for cancellation
  ///     try Task.checkCancellation()
  ///
  ///     if page.next == nil { break }
  ///     offset += limit
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - pageSize: Number of items per request (clamped to 1-50).
  ///   - maxItems: Optional limit on total items to fetch. Recommended for large collections.
  ///   - fetchPage: Closure that fetches a single page given limit and offset.
  /// - Returns: Array of all collected items.
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

import Foundation

/// Reports progress for batch operations that process items in chunks.
///
/// This struct provides feedback during operations like saving multiple albums,
/// removing tracks, or adding items to playlists, which may require multiple
/// API requests when the number of items exceeds the API's batch size limits.
///
/// ```swift
/// try await client.albums.saveAll(albumIDs) { progress in
///     print("Saved \(progress.completed) of \(progress.total) batches")
///     print("Current batch has \(progress.currentBatchSize) items")
/// }
/// ```
public struct BatchProgress: Sendable, Equatable {
  /// The number of batches completed so far.
  public let completed: Int

  /// The total number of batches to process.
  public let total: Int

  /// The number of items in the current batch being processed.
  public let currentBatchSize: Int

  /// Creates a new batch progress report.
  ///
  /// - Parameters:
  ///   - completed: The number of batches completed (0-indexed, incremented after each batch).
  ///   - total: The total number of batches.
  ///   - currentBatchSize: The number of items in the current batch.
  public init(completed: Int, total: Int, currentBatchSize: Int) {
    self.completed = completed
    self.total = total
    self.currentBatchSize = currentBatchSize
  }
}

/// A callback type for reporting batch operation progress.
///
/// The callback is invoked before processing each batch, allowing consumers to:
/// - Update UI progress indicators
/// - Log processing status
/// - Implement rate limiting
/// - Cancel operations conditionally
///
/// The callback is marked as `@Sendable` to ensure thread safety when used
/// with Swift's structured concurrency.
public typealias BatchProgressCallback = @Sendable (BatchProgress) -> Void

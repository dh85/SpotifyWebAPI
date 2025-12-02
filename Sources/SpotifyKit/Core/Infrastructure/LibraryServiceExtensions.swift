import Foundation

// MARK: - Albums Batch Operations

/// Convenience extensions for batch library operations.
extension AlbumsService where Capability == UserAuthCapability {

  /// Save albums to library, automatically chunking into batches of 20.
  ///
  /// Spotify's API limits saving albums to 20 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.albums.saveAll(["album1", "album2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.albums.saveAll(albumIDs) { progress in
  ///     print("Saved \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Album IDs to save.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func saveAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(from: ids, chunkSize: SpotifyAPILimits.Albums.batchSize)
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await save(batch)
    }
  }

  /// Remove albums from library, automatically chunking into batches of 20.
  ///
  /// Spotify's API limits removing albums to 20 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.albums.removeAll(["album1", "album2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.albums.removeAll(albumIDs) { progress in
  ///     print("Removed \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Album IDs to remove.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func removeAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(from: ids, chunkSize: SpotifyAPILimits.Albums.batchSize)
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await remove(batch)
    }
  }
}

// MARK: - Tracks Batch Operations

extension TracksService where Capability == UserAuthCapability {

  /// Save tracks to library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits saving tracks to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.tracks.saveAll(["track1", "track2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.tracks.saveAll(trackIDs) { progress in
  ///     print("Saved \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Track IDs to save.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func saveAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Tracks.libraryBatchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await save(batch)
    }
  }

  /// Remove tracks from library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits removing tracks to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.tracks.removeAll(["track1", "track2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.tracks.removeAll(trackIDs) { progress in
  ///     print("Removed \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Track IDs to remove.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func removeAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Tracks.libraryBatchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await remove(batch)
    }
  }
}

// MARK: - Shows Batch Operations

extension ShowsService where Capability == UserAuthCapability {

  /// Save shows to library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits saving shows to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.shows.saveAll(["show1", "show2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.shows.saveAll(showIDs) { progress in
  ///     print("Saved \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Show IDs to save.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func saveAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Shows.batchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await save(batch)
    }
  }

  /// Remove shows from library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits removing shows to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.shows.removeAll(["show1", "show2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.shows.removeAll(showIDs) { progress in
  ///     print("Removed \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Show IDs to remove.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func removeAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Shows.batchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await remove(batch)
    }
  }
}

// MARK: - Episodes Batch Operations

extension EpisodesService where Capability == UserAuthCapability {

  /// Save episodes to library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits saving episodes to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.episodes.saveAll(["episode1", "episode2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.episodes.saveAll(episodeIDs) { progress in
  ///     print("Saved \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Episode IDs to save.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func saveAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Episodes.batchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await save(batch)
    }
  }

  /// Remove episodes from library, automatically chunking into batches of 50.
  ///
  /// Spotify's API limits removing episodes to 50 per request. This method automatically
  /// splits large arrays into multiple requests and deduplicates IDs.
  ///
  /// ```swift
  /// try await client.episodes.removeAll(["episode1", "episode2", ...])
  /// ```
  ///
  /// Optionally track progress:
  /// ```swift
  /// try await client.episodes.removeAll(episodeIDs) { progress in
  ///     print("Removed \(progress.completed)/\(progress.total) batches")
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - ids: Episode IDs to remove.
  ///   - progress: Optional callback invoked before processing each batch.
  /// - Throws: ``SpotifyClientError`` if any request fails.
  public func removeAll(_ ids: [String], progress: BatchProgressCallback? = nil) async throws {
    let batches = chunkedUniqueSets(
      from: ids,
      chunkSize: SpotifyAPILimits.Episodes.batchSize
    )
    let total = batches.count
    for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()
      progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
      try await remove(batch)
    }
  }
}

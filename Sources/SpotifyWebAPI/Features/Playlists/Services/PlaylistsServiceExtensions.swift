import Foundation

// MARK: - Batch Operations

/// Convenience extensions for batch playlist operations.
extension PlaylistsService where Capability == UserAuthCapability {

    /// Add tracks to a playlist, automatically chunking into batches of 100.
    ///
    /// Spotify's API limits adding tracks to 100 per request. This method automatically
    /// splits large arrays into multiple requests.
    ///
    /// ```swift
    /// let trackURIs = ["spotify:track:abc123", "spotify:track:def456", ...]
    /// try await client.playlists.addTracks(trackURIs, to: "playlist-id")
    /// ```
    ///
    /// Optionally track progress:
    /// ```swift
    /// try await client.playlists.addTracks(trackURIs, to: playlistID) { progress in
    ///     print("Added \(progress.completed)/\(progress.total) batches")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - trackURIs: Track/episode URIs to add (e.g., "spotify:track:abc123").
    ///   - playlistID: The Spotify ID for the playlist.
    ///   - progress: Optional callback invoked before processing each batch.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func addTracks(
        _ trackURIs: [String],
        to playlistID: String,
        progress: BatchProgressCallback? = nil
    ) async throws {
        let batches = chunkedArrays(
            from: trackURIs,
            chunkSize: SpotifyAPILimits.Playlists.itemMutationBatchSize
        )
        let total = batches.count
        for (index, batch) in batches.enumerated() {
            try Task.checkCancellation()
            progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
            _ = try await add(to: playlistID, uris: batch)
        }
    }

    /// Remove tracks from a playlist, automatically chunking into batches of 100.
    ///
    /// Spotify's API limits removing tracks to 100 per request. This method automatically
    /// splits large arrays into multiple requests.
    ///
    /// ```swift
    /// let trackURIs = ["spotify:track:abc123", "spotify:track:def456", ...]
    /// try await client.playlists.removeTracks(trackURIs, from: "playlist-id")
    /// ```
    ///
    /// Optionally track progress:
    /// ```swift
    /// try await client.playlists.removeTracks(trackURIs, from: playlistID) { progress in
    ///     print("Removed \(progress.completed)/\(progress.total) batches")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - trackURIs: Track/episode URIs to remove (e.g., "spotify:track:abc123").
    ///   - playlistID: The Spotify ID for the playlist.
    ///   - progress: Optional callback invoked before processing each batch.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func removeTracks(
        _ trackURIs: [String],
        from playlistID: String,
        progress: BatchProgressCallback? = nil
    ) async throws {
        let batches = chunkedArrays(
            from: trackURIs,
            chunkSize: SpotifyAPILimits.Playlists.itemMutationBatchSize
        )
        let total = batches.count
        for (index, batch) in batches.enumerated() {
            try Task.checkCancellation()
            progress?(BatchProgress(completed: index, total: total, currentBatchSize: batch.count))
            _ = try await remove(from: playlistID, uris: batch)
        }
    }
}

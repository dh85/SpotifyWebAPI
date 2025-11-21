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
    /// - Parameter ids: Album IDs to save.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 20) {
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
    /// - Parameter ids: Album IDs to remove.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func removeAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 20) {
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
    /// - Parameter ids: Track IDs to save.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
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
    /// - Parameter ids: Track IDs to remove.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func removeAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
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
    /// - Parameter ids: Show IDs to save.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
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
    /// - Parameter ids: Show IDs to remove.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func removeAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
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
    /// - Parameter ids: Episode IDs to save.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
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
    /// - Parameter ids: Episode IDs to remove.
    /// - Throws: ``SpotifyError`` if any request fails.
    public func removeAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
            try await remove(batch)
        }
    }
}

// MARK: - Set Chunking

fileprivate extension Set {
    func chunked(into size: Int) -> [Set<Element>] {
        let array = Array(self)
        return stride(from: 0, to: array.count, by: size).map {
            Set(array[$0..<Swift.min($0 + size, array.count)])
        }
    }
}

import Foundation

// MARK: - Albums Batch Operations

extension AlbumsService where Capability == UserAuthCapability {

    /// Save albums to library, automatically chunking into batches of 20.
    ///
    /// - Parameter ids: Album IDs to save.
    /// - Throws: `SpotifyError` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 20) {
            try await save(batch)
        }
    }

    /// Remove albums from library, automatically chunking into batches of 20.
    ///
    /// - Parameter ids: Album IDs to remove.
    /// - Throws: `SpotifyError` if any request fails.
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
    /// - Parameter ids: Track IDs to save.
    /// - Throws: `SpotifyError` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
            try await save(batch)
        }
    }

    /// Remove tracks from library, automatically chunking into batches of 50.
    ///
    /// - Parameter ids: Track IDs to remove.
    /// - Throws: `SpotifyError` if any request fails.
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
    /// - Parameter ids: Show IDs to save.
    /// - Throws: `SpotifyError` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
            try await save(batch)
        }
    }

    /// Remove shows from library, automatically chunking into batches of 50.
    ///
    /// - Parameter ids: Show IDs to remove.
    /// - Throws: `SpotifyError` if any request fails.
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
    /// - Parameter ids: Episode IDs to save.
    /// - Throws: `SpotifyError` if any request fails.
    public func saveAll(_ ids: [String]) async throws {
        for batch in Set(ids).chunked(into: 50) {
            try await save(batch)
        }
    }

    /// Remove episodes from library, automatically chunking into batches of 50.
    ///
    /// - Parameter ids: Episode IDs to remove.
    /// - Throws: `SpotifyError` if any request fails.
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

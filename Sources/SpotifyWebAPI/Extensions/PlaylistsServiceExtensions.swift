import Foundation

// MARK: - Batch Operations

extension PlaylistsService where Capability == UserAuthCapability {

    /// Add tracks to a playlist, automatically chunking into batches of 100.
    ///
    /// - Parameters:
    ///   - trackURIs: Track/episode URIs to add.
    ///   - playlistID: The Spotify ID for the playlist.
    /// - Throws: `SpotifyError` if any request fails.
    public func addTracks(_ trackURIs: [String], to playlistID: String) async throws {
        for batch in trackURIs.chunked(into: 100) {
            _ = try await add(to: playlistID, uris: batch)
        }
    }

    /// Remove tracks from a playlist, automatically chunking into batches of 100.
    ///
    /// - Parameters:
    ///   - trackURIs: Track/episode URIs to remove.
    ///   - playlistID: The Spotify ID for the playlist.
    /// - Throws: `SpotifyError` if any request fails.
    public func removeTracks(_ trackURIs: [String], from playlistID: String) async throws {
        for batch in trackURIs.chunked(into: 100) {
            _ = try await remove(from: playlistID, uris: batch)
        }
    }
}

// MARK: - Array Chunking

fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

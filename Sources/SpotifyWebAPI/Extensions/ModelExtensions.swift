import Foundation

// MARK: - Playlist Convenience

/// Convenience properties for playlists.
extension Playlist {
    /// Total number of tracks/episodes in the playlist.
    public var totalTracks: Int { tracks.total }
    
    /// Whether the playlist is empty (has no tracks).
    public var isEmpty: Bool { tracks.total == 0 }
}

/// Convenience properties for simplified playlists.
extension SimplifiedPlaylist {
    /// Total number of tracks/episodes in the playlist.
    public var totalTracks: Int { tracks?.total ?? 0 }
    
    /// Whether the playlist is empty (has no tracks).
    public var isEmpty: Bool { tracks?.total == 0 }
}

// MARK: - Album Convenience

/// Convenience properties for albums.
extension Album {
    /// All artist names joined by commas (e.g., "Artist 1, Artist 2").
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

/// Convenience properties for simplified albums.
extension SimplifiedAlbum {
    /// All artist names joined by commas (e.g., "Artist 1, Artist 2").
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

// MARK: - Track Convenience

/// Convenience properties for tracks.
extension Track {
    /// All artist names joined by commas (e.g., "Artist 1, Artist 2").
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
    
    /// Duration formatted as minutes:seconds (e.g., "3:45").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Convenience properties for simplified tracks.
extension SimplifiedTrack {
    /// All artist names joined by commas (e.g., "Artist 1, Artist 2").
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
    
    /// Duration formatted as minutes:seconds (e.g., "3:45").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Episode Convenience

/// Convenience properties for episodes.
extension Episode {
    /// Duration formatted as minutes:seconds (e.g., "45:30").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Convenience properties for simplified episodes.
extension SimplifiedEpisode {
    /// Duration formatted as minutes:seconds (e.g., "45:30").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Image Convenience

/// Convenience properties for images.
extension SpotifyImage {
    /// Whether this is a high-resolution image (width >= 640px).
    public var isHighRes: Bool {
        guard let width else { return false }
        return width >= 640
    }
    
    /// Whether this is a thumbnail image (width < 200px).
    public var isThumbnail: Bool {
        guard let width else { return false }
        return width < 200
    }
}

/// Convenience properties for image arrays.
extension Array where Element == SpotifyImage {
    /// The largest image by width.
    ///
    /// ```swift
    /// if let coverArt = album.images.largest {
    ///     print("Cover art: \(coverArt.url)")
    /// }
    /// ```
    public var largest: SpotifyImage? {
        self.max { ($0.width ?? 0) < ($1.width ?? 0) }
    }
    
    /// The smallest image by width.
    ///
    /// ```swift
    /// if let thumbnail = album.images.smallest {
    ///     print("Thumbnail: \(thumbnail.url)")
    /// }
    /// ```
    public var smallest: SpotifyImage? {
        self.min { ($0.width ?? 0) < ($1.width ?? 0) }
    }
}

import Foundation

// MARK: - Playlist Convenience

extension Playlist {
    /// Total number of tracks/episodes in the playlist.
    public var totalTracks: Int { tracks.total }
    
    /// Whether the playlist is empty.
    public var isEmpty: Bool { tracks.total == 0 }
}

extension SimplifiedPlaylist {
    /// Total number of tracks/episodes in the playlist.
    public var totalTracks: Int { tracks?.total ?? 0 }
    
    /// Whether the playlist is empty.
    public var isEmpty: Bool { tracks?.total == 0 }
}

// MARK: - Album Convenience

extension Album {
    /// All artist names joined by commas.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

extension SimplifiedAlbum {
    /// All artist names joined by commas.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
}

// MARK: - Track Convenience

extension Track {
    /// All artist names joined by commas.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
    
    /// Duration in minutes and seconds (e.g., "3:45").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension SimplifiedTrack {
    /// All artist names joined by commas.
    public var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }
    
    /// Duration in minutes and seconds (e.g., "3:45").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Episode Convenience

extension Episode {
    /// Duration in minutes and seconds (e.g., "45:30").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension SimplifiedEpisode {
    /// Duration in minutes and seconds (e.g., "45:30").
    public var durationFormatted: String {
        let minutes = durationMs / 60000
        let seconds = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Image Convenience

extension SpotifyImage {
    /// Whether this is a high-resolution image (width >= 640).
    public var isHighRes: Bool {
        guard let width else { return false }
        return width >= 640
    }
    
    /// Whether this is a thumbnail image (width < 200).
    public var isThumbnail: Bool {
        guard let width else { return false }
        return width < 200
    }
}

extension Array where Element == SpotifyImage {
    /// The largest image by width.
    public var largest: SpotifyImage? {
        self.max { ($0.width ?? 0) < ($1.width ?? 0) }
    }
    
    /// The smallest image by width.
    public var smallest: SpotifyImage? {
        self.min { ($0.width ?? 0) < ($1.width ?? 0) }
    }
}

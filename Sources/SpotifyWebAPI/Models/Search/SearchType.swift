import Foundation

/// The type of item to search for.
public enum SearchType: String, Sendable, Equatable, CaseIterable {
    case album
    case artist
    case playlist
    case track
    case show
    case episode
    case audiobook
}

extension Set where Element == SearchType {
    /// Creates the comma-separated list Spotify expects for the 'type' query.
    var spotifyQueryValue: String {
        map(\.rawValue).sorted().joined(separator: ",")
    }
}

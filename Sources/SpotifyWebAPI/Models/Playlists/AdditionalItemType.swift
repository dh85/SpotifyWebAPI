import Foundation

/// Additional item types to include in playlist responses.
public enum AdditionalItemType: String, Sendable, Equatable, CaseIterable {
    case track
    case episode
}

extension Set where Element == AdditionalItemType {
    /// Creates the comma-separated list Spotify expects for the 'additional_types' query.
    var spotifyQueryValue: String {
        map(\.rawValue).sorted().joined(separator: ",")
    }
}

import Foundation

/// A simple wrapper for a track URI.
/// Used in the body of 'removePlaylistItems'.
struct TrackURIObject: Encodable, Sendable, Equatable {
    let uri: String
}

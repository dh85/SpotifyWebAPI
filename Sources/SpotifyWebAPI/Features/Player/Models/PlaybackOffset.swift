import Foundation

/// Represents an offset in a playback context (e.g., album or playlist).
///
/// Used to specify where playback should start.
public struct PlaybackOffset: Encodable, Sendable, Equatable {
    /// The 0-indexed position.
    public let position: Int?

    /// The URI of the track to start at.
    public let uri: String?

    /// Private init to prevent creating an invalid state.
    private init(position: Int?, uri: String?) {
        self.position = position
        self.uri = uri
    }

    /// Create an offset by position (index).
    public static func position(_ pos: Int) -> PlaybackOffset {
        PlaybackOffset(position: pos, uri: nil)
    }

    /// Create an offset by track URI.
    public static func uri(_ uri: String) -> PlaybackOffset {
        PlaybackOffset(position: nil, uri: uri)
    }
}

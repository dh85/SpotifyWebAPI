import Foundation

/// A Saved Audiobook Object (from user's library).
///
/// Source: `GET /v1/me/audiobooks`
public struct SavedAudiobook: SavedItem {
    /// The date and time the audiobook was saved.
    public let addedAt: Date

    /// Information about the audiobook.
    public let audiobook: Audiobook

    public var content: Audiobook { audiobook }
}

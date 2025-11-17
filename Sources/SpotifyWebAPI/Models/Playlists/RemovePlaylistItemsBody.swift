import Foundation

/// Request body for `DELETE /v1/playlists/{id}/tracks` (Remove Items).
struct RemovePlaylistItemsBody: Encodable, Sendable, Equatable {
    /// List of track/episode URI objects to remove.
    let tracks: [TrackURIObject]?

    /// List of 0-indexed positions to remove.
    let positions: [Int]?

    /// The playlist's snapshot ID (for optimistic locking).
    let snapshotId: String?

    enum CodingKeys: String, CodingKey {
        case tracks, positions
        case snapshotId = "snapshot_id"
    }

    /// Creates a request body to remove items by their URIs.
    static func byURIs(_ uris: [String], snapshotId: String? = nil) -> Self {
        let trackObjects = uris.map { TrackURIObject(uri: $0) }
        return .init(
            tracks: trackObjects,
            positions: nil,
            snapshotId: snapshotId
        )
    }

    /// Creates a request body to remove items by their positions.
    static func byPositions(_ positions: [Int], snapshotId: String? = nil)
        -> Self
    {
        // "tracks" field must be an empty array if removing by position
        return .init(tracks: [], positions: positions, snapshotId: snapshotId)
    }
}

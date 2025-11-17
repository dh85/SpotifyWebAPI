import Foundation

/// Request body for `PUT /v1/playlists/{id}/tracks` (Reorder action).
struct ReorderPlaylistItemsBody: Encodable {
    let rangeStart: Int
    let insertBefore: Int
    let rangeLength: Int?
    let snapshotId: String?

    enum CodingKeys: String, CodingKey {
        case rangeStart = "range_start"
        case insertBefore = "insert_before"
        case rangeLength = "range_length"
        case snapshotId = "snapshot_id"
    }
}

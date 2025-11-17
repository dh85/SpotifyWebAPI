import Foundation

/// Request body for `POST /v1/playlists/{id}/tracks` (Add Items).
struct AddPlaylistItemsBody: Encodable {
    /// A list of track/episode URIs.
    let uris: [String]

    /// The 0-indexed position to insert the items.
    let position: Int?
}

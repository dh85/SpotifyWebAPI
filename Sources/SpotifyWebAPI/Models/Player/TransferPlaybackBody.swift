import Foundation

/// Request body for `PUT /v1/me/player` (Transfer Playback).
struct TransferPlaybackBody: Encodable {
    let deviceIds: [String]

    /// `true`: ensure playback starts. `false` or `nil`: keep current state.
    let play: Bool?

    enum CodingKeys: String, CodingKey {
        case deviceIds = "device_ids"
        case play
    }
}

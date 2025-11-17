import Foundation

/// Request body for `PUT /v1/me/player/play`.
struct StartPlaybackBody: Encodable {
    let contextUri: String?
    let uris: [String]?
    let offset: PlaybackOffset?
    let positionMs: Int?

    enum CodingKeys: String, CodingKey {
        case contextUri = "context_uri"
        case uris
        case offset
        case positionMs = "position_ms"
    }

    /// Body for resuming playback.
    static var resume: StartPlaybackBody {
        StartPlaybackBody(
            contextUri: nil,
            uris: nil,
            offset: nil,
            positionMs: nil
        )
    }

    /// Body for playing a context (album, playlist, artist).
    static func context(
        _ uri: String,
        offset: PlaybackOffset? = nil,
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(
            contextUri: uri,
            uris: nil,
            offset: offset,
            positionMs: positionMs
        )
    }

    /// Body for playing a list of tracks.
    static func tracks(
        _ uris: [String],
        positionMs: Int? = nil
    ) -> StartPlaybackBody {
        StartPlaybackBody(
            contextUri: nil,
            uris: uris,
            offset: nil,  // Offset is not valid for 'uris'
            positionMs: positionMs
        )
    }
}

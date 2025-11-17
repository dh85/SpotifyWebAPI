import Foundation

/// Wrapper for the `GET /v1/tracks` endpoint response.
struct SeveralTracksResponse: Codable, Sendable, Equatable {
    /// A list of tracks.
    /// Note: Objects in this list can be null if an ID was not found.
    /// However, the decoder will typically filter or throw depending on configuration.
    /// For safety, 'Track' properties are usually optional anyway.
    let tracks: [Track?]
}

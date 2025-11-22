/// Copyright information for an album or track.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public struct SpotifyCopyright: Codable, Sendable, Equatable {
    /// The type of copyright.
    public enum CopyrightType: String, Codable, Equatable, Sendable {
        /// Copyright (©) - The copyright.
        case copyright = "C"
        /// Performance (℗) - The sound recording (phonogram) copyright.
        case performance = "P"
    }

    /// The copyright text.
    public let text: String
    /// The type of copyright.
    public let type: CopyrightType
}

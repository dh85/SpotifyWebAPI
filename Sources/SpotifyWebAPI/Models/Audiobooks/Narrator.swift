/// Audiobook narrator information.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-audiobook)
public struct Narrator: Codable, Sendable, Equatable {
    /// The name of the narrator.
    public let name: String
}

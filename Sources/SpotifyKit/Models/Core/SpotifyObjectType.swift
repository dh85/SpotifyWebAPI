/// The object type returned by the Spotify API.
///
/// Used to identify the type of Spotify resource (album, artist, track, etc.).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/concepts/api-calls)
public enum SpotifyObjectType: String, Codable, Equatable, Sendable {
    case album
    case artist
    case audiobook
    case chapter
    case episode
    case playlist
    case show
    case track
    case user
}

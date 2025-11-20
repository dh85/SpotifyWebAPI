import Foundation

/// Image information for an album, artist, playlist, or other resource.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-album)
public struct SpotifyImage: Codable, Sendable, Equatable {
    /// The source URL of the image.
    public let url: URL
    /// The image height in pixels.
    public let height: Int?
    /// The image width in pixels.
    public let width: Int?
}

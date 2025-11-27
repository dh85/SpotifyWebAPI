import Foundation

/// External URLs for a Spotify resource.
///
/// Contains links to open the resource in the Spotify web player or app.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-track)
public struct SpotifyExternalUrls: Codable, Sendable, Equatable {
    /// The Spotify URL for the object (e.g., "https://open.spotify.com/track/...").
    public let spotify: URL?
}

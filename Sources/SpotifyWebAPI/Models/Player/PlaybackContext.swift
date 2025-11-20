import Foundation

/// The context of the current playback.
public struct PlaybackContext: Codable, Sendable, Equatable {
    /// The object type, such as "artist", "playlist", "album", or "show".
    public let type: String

    /// A link to the Web API endpoint providing full details.
    public let href: URL

    /// External URLs for this context.
    public let externalUrls: SpotifyExternalUrls

    /// The Spotify URI for the context.
    public let uri: String
}

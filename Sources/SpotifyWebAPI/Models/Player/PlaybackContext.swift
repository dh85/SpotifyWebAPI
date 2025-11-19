import Foundation

/// The context of the current playback.
public struct PlaybackContext: Codable, Sendable, Equatable {
    /// The type of context (e.g., "album", "playlist", "artist").
    public let type: PlaybackContextType

    /// A link to the Web API endpoint providing full details.
    public let href: URL

    /// External URLs for this context.
    public let externalUrls: SpotifyExternalUrls

    /// The Spotify URI for the context.
    public let uri: String
}

extension PlaybackContext {
    public enum PlaybackContextType: String, Codable, Sendable {
        case album = "album"
        case playlist = "playlist"
        case artist = "artist"
        case show = "show"
    }
}

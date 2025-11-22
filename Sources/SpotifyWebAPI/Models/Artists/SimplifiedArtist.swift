import Foundation

/// Simplified artist object containing basic artist information.
///
/// This is a lighter version of the full Artist object, typically returned in contexts
/// where complete artist details are not needed (e.g., within tracks, albums).
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/reference/get-an-artist)
public struct SimplifiedArtist: Codable, Sendable, Equatable {
    /// Known external URLs for this artist.
    public let externalUrls: SpotifyExternalUrls?
    /// A link to the Web API endpoint providing full details of the artist.
    public let href: URL?
    /// The Spotify ID for the artist.
    public let id: String?
    /// The name of the artist.
    public let name: String
    /// The object type (always "artist").
    public let type: SpotifyObjectType
    /// The Spotify URI for the artist.
    public let uri: String?
}

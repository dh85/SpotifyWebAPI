import Foundation

/// Common metadata returned by many Spotify resources (albums, artists, playlists, etc.).
///
/// By conforming to this protocol, models can expose a consistent surface for
/// identifying resources without duplicating helper code.
public protocol SpotifyResource: Sendable {
    var externalUrls: SpotifyExternalUrls? { get }
    var hrefURL: URL? { get }
    var spotifyID: String? { get }
    var displayName: String { get }
    var objectType: SpotifyObjectType { get }
    var spotifyURI: String? { get }
}

public extension SpotifyResource {
    var resourceSummary: String {
        "\(displayName) (\(spotifyID ?? "unknown"))"
    }
}

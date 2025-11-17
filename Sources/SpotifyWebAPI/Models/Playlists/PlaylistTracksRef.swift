import Foundation

/// Reference structure embedded inside SimplifiedPlaylist.
/// Only provides track count and a link to the `/tracks` endpoint.
public struct PlaylistTracksRef: Codable, Sendable, Equatable {
    public let href: URL?
    public let total: Int
}

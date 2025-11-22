import Foundation

extension Album {
    public var hrefURL: URL? { href }
    public var spotifyID: String? { id }
    public var displayName: String { name }
    public var objectType: SpotifyObjectType { type }
    public var spotifyURI: String? { uri }
}

extension SimplifiedAlbum {
    public var hrefURL: URL? { href }
    public var spotifyID: String? { id }
    public var displayName: String { name }
    public var objectType: SpotifyObjectType { type }
    public var spotifyURI: String? { uri }
}

extension SimplifiedArtist {
    public var hrefURL: URL? { href }
    public var spotifyID: String? { id }
    public var displayName: String { name }
    public var objectType: SpotifyObjectType { type }
    public var spotifyURI: String? { uri }
}

extension Playlist {
    public var hrefURL: URL? { href }
    public var spotifyID: String? { id }
    public var displayName: String { name }
    public var objectType: SpotifyObjectType { type }
    public var spotifyURI: String? { uri }
}

extension SimplifiedPlaylist {
    public var hrefURL: URL? { href }
    public var spotifyID: String? { id }
    public var displayName: String { name }
    public var objectType: SpotifyObjectType { type }
    public var spotifyURI: String? { uri }
}

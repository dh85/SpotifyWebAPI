import Foundation

// StandardSpotifyResource conformance provides automatic implementations for:
// - Album
// - SimplifiedAlbum
// - SimplifiedArtist
//
// These models no longer need explicit extensions here since the protocol
// provides default implementations that map standard Spotify API properties
// (href, id, name, type, uri) to the SpotifyResource protocol requirements.

// Playlist models have non-optional properties (href: URL, id: String, uri: String)
// so they don't conform to StandardSpotifyResource and need manual extensions.

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

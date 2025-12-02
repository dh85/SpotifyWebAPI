import Foundation

extension SpotifyClient {
  /// Access Player controls (Play, Pause, Queue, etc).
  public var player: PlayerService<Capability> {
    PlayerService(client: self)
  }

  /// Access Playlist operations (Create, Follow, Add Tracks).
  public var playlists: PlaylistsService<Capability> {
    PlaylistsService(client: self)
  }

  /// Access User profile, Follow lists, and Top items.
  public var users: UsersService<Capability> {
    UsersService(client: self)
  }

  /// Search for items.
  public var search: SearchService<Capability> {
    SearchService(client: self)
  }

  /// Access Browse features (New Releases, Categories).
  public var browse: BrowseService<Capability> {
    BrowseService(client: self)
  }

  // MARK: - Catalog Services

  public var albums: AlbumsService<Capability> {
    AlbumsService(client: self)
  }

  public var artists: ArtistsService<Capability> {
    ArtistsService(client: self)
  }

  public var tracks: TracksService<Capability> {
    TracksService(client: self)
  }

  public var shows: ShowsService<Capability> {
    ShowsService(client: self)
  }

  public var audiobooks: AudiobooksService<Capability> {
    AudiobooksService(client: self)
  }

  public var episodes: EpisodesService<Capability> {
    EpisodesService(client: self)
  }

  public var chapters: ChaptersService<Capability> {
    ChaptersService(client: self)
  }
}

import Foundation

extension SpotifyClient {
    /// Access Playlist operations (Create, Follow, Add Tracks).
    public nonisolated var playlists: PlaylistsService<Capability> {
        PlaylistsService(client: self)
    }

    /// Access User profile, Follow lists, and Top items.
    public nonisolated var users: UsersService<Capability> {
        UsersService(client: self)
    }

    /// Search for items.
    public nonisolated var search: SearchService<Capability> {
        SearchService(client: self)
    }

    /// Access Browse features (New Releases, Categories).
    public nonisolated var browse: BrowseService<Capability> {
        BrowseService(client: self)
    }

    // MARK: - Catalog Services

    public nonisolated var albums: AlbumsService<Capability> {
        AlbumsService(client: self)
    }

    public nonisolated var artists: ArtistsService<Capability> {
        ArtistsService(client: self)
    }

    public nonisolated var tracks: TracksService<Capability> {
        TracksService(client: self)
    }

    public nonisolated var shows: ShowsService<Capability> {
        ShowsService(client: self)
    }

    public nonisolated var audiobooks: AudiobooksService<Capability> {
        AudiobooksService(client: self)
    }

    public nonisolated var episodes: EpisodesService<Capability> {
        EpisodesService(client: self)
    }

    public nonisolated var chapters: ChaptersService<Capability> {
        ChaptersService(client: self)
    }
}

extension SpotifyClient where Capability: UserSpotifyCapability {
    /// Access Player controls (Play, Pause, Queue, etc).
    public nonisolated var player: PlayerService<Capability> {
        PlayerService(client: self)
    }
}

extension SpotifyClient where Capability == AppOnlyAuthCapability {
    @available(*, unavailable, message: "Player endpoints require a user-authenticated client.")
    public var player: PlayerService<Capability> {
        fatalError("Player service is unavailable for app-only clients.")
    }
}

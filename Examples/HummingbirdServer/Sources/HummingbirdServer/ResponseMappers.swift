import Foundation
import SpotifyWebAPI

// MARK: - Mappers: Convert SpotifyWebAPI models to Response models

// Typealias to resolve naming conflict with nested PlayHistoryItem type
typealias SpotifyPlayHistoryItem = PlayHistoryItem

extension UserProfileResponse {
    init(from profile: CurrentUserProfile) {
        self.init(
            id: profile.id,
            displayName: profile.displayName ?? "",
            email: profile.email ?? "",
            country: profile.country ?? "",
            product: profile.product ?? "",
            followers: profile.followers.total,
            images: profile.images.map { ImageResponse(from: $0) }
        )
    }
}

extension ImageResponse {
    init(from image: SpotifyImage) {
        self.init(url: image.url.absoluteString, width: image.width ?? 0, height: image.height ?? 0)
    }
}

extension PlaylistsResponse {
    init(from page: Page<SimplifiedPlaylist>) {
        self.init(
            total: page.total,
            items: page.items.map { PlaylistItem(from: $0) }
        )
    }
}

extension PlaylistsResponse.PlaylistItem {
    init(from playlist: SimplifiedPlaylist) {
        self.init(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description ?? "",
            isPublic: playlist.isPublic ?? false,
            trackCount: playlist.tracks?.total ?? 0,
            owner: Owner(
                id: playlist.owner?.id ?? "",
                displayName: playlist.owner?.displayName ?? ""
            ),
            images: playlist.images.map { ImageResponse(from: $0) }
        )
    }
}

extension TopArtistsResponse {
    init(from page: Page<Artist>) {
        self.init(
            total: page.total,
            items: page.items.map { ArtistItem(from: $0) }
        )
    }
}

extension TopArtistsResponse.ArtistItem {
    init(from artist: Artist) {
        self.init(
            id: artist.id ?? "",
            name: artist.name,
            genres: artist.genres ?? [],
            popularity: artist.popularity ?? 0,
            followers: artist.followers?.total ?? 0,
            images: artist.images?.map { ImageResponse(from: $0) } ?? []
        )
    }
}

extension TopTracksResponse {
    init(from page: Page<Track>) {
        self.init(
            total: page.total,
            items: page.items.map { TrackItem(from: $0) }
        )
    }
}

extension TopTracksResponse.TrackItem {
    init(from track: Track) {
        self.init(
            id: track.id ?? "",
            name: track.name,
            artists: track.artists?.map { ArtistRef(from: $0) } ?? [],
            album: AlbumRef(from: track.album),
            durationMs: track.durationMs ?? 0,
            popularity: track.popularity ?? 0
        )
    }
}

extension TopTracksResponse.TrackItem.ArtistRef {
    init(from artist: SimplifiedArtist) {
        self.init(id: artist.id, name: artist.name)
    }
}

extension TopTracksResponse.TrackItem.AlbumRef {
    init(from album: SimplifiedAlbum?) {
        self.init(id: album?.id ?? "", name: album?.name ?? "")
    }
}

extension RecentlyPlayedResponse {
    init(from page: CursorBasedPage<SpotifyPlayHistoryItem>) {
        self.init(items: page.items.map { PlayHistoryItem(from: $0) })
    }
}

extension RecentlyPlayedResponse.PlayHistoryItem {
    init(from item: SpotifyPlayHistoryItem) {
        self.init(
            playedAt: ISO8601DateFormatter().string(from: item.playedAt),
            track: TrackInfo(from: item.track)
        )
    }
}

extension RecentlyPlayedResponse.PlayHistoryItem.TrackInfo {
    init(from track: Track) {
        self.init(
            id: track.id ?? "",
            name: track.name,
            artists: track.artists?.map { Artist(name: $0.name) } ?? [],
            album: Album(name: track.album?.name ?? "")
        )
    }
}

extension SearchResponse {
    init(from results: SearchResults) {
        self.init(
            tracks: results.tracks?.items.map { SearchTrack(from: $0) },
            artists: results.artists?.items.map { SearchArtist(from: $0) },
            albums: results.albums?.items.map { SearchAlbum(from: $0) }
        )
    }
}

extension SearchResponse.SearchTrack {
    init(from track: Track) {
        self.init(
            id: track.id ?? "",
            name: track.name,
            artists: track.artists?.map { $0.name }.joined(separator: ", ") ?? ""
        )
    }
}

extension SearchResponse.SearchArtist {
    init(from artist: Artist) {
        self.init(
            id: artist.id ?? "",
            name: artist.name,
            genres: artist.genres?.joined(separator: ", ") ?? ""
        )
    }
}

extension SearchResponse.SearchAlbum {
    init(from album: SimplifiedAlbum) {
        self.init(
            id: album.id ?? "",
            name: album.name,
            artists: album.artists?.map { $0.name }.joined(separator: ", ") ?? ""
        )
    }
}

extension AlbumResponse {
    init(from album: Album) {
        self.init(
            id: album.id ?? "",
            name: album.name,
            artists: album.artists?.map { Artist(from: $0) } ?? [],
            releaseDate: album.releaseDate ?? "",
            totalTracks: album.totalTracks ?? 0,
            label: album.label ?? "",
            popularity: album.popularity ?? 0,
            tracks: album.tracks?.items.map { Track(from: $0) } ?? []
        )
    }
}

extension AlbumResponse.Artist {
    init(from artist: SimplifiedArtist) {
        self.init(id: artist.id ?? "", name: artist.name)
    }
}

extension AlbumResponse.Track {
    init(from track: SimplifiedTrack) {
        self.init(
            id: track.id ?? "",
            name: track.name,
            trackNumber: track.trackNumber ?? 0,
            durationMs: track.durationMs ?? 0
        )
    }
}

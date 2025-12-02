import Foundation

// MARK: - Response Models

struct UserProfileResponse: Codable {
  let id: String
  let displayName: String
  let email: String
  let country: String
  let product: String
  let followers: Int
  let images: [ImageResponse]
}

struct ImageResponse: Codable {
  let url: String
  let width: Int
  let height: Int
}

struct PlaylistsResponse: Codable {
  let total: Int
  let items: [PlaylistItem]

  struct PlaylistItem: Codable {
    let id: String
    let name: String
    let description: String
    let isPublic: Bool
    let trackCount: Int
    let owner: Owner
    let images: [ImageResponse]

    struct Owner: Codable {
      let id: String
      let displayName: String
    }
  }
}

struct TopArtistsResponse: Codable {
  let total: Int
  let items: [ArtistItem]

  struct ArtistItem: Codable {
    let id: String
    let name: String
    let genres: [String]
    let popularity: Int
    let followers: Int
    let images: [ImageResponse]
  }
}

struct TopTracksResponse: Codable {
  let total: Int
  let items: [TrackItem]

  struct TrackItem: Codable {
    let id: String
    let name: String
    let artists: [ArtistRef]
    let album: AlbumRef
    let durationMs: Int
    let popularity: Int

    struct ArtistRef: Codable {
      let id: String?
      let name: String
    }

    struct AlbumRef: Codable {
      let id: String
      let name: String
    }
  }
}

struct RecentlyPlayedResponse: Codable {
  let items: [PlayHistoryItem]

  struct PlayHistoryItem: Codable {
    let playedAt: String
    let track: TrackInfo

    struct TrackInfo: Codable {
      let id: String
      let name: String
      let artists: [Artist]
      let album: Album

      struct Artist: Codable {
        let name: String
      }

      struct Album: Codable {
        let name: String
      }
    }
  }
}

struct SearchResponse: Codable {
  let tracks: [SearchTrack]?
  let artists: [SearchArtist]?
  let albums: [SearchAlbum]?

  struct SearchTrack: Codable {
    let id: String
    let name: String
    let artists: String
  }

  struct SearchArtist: Codable {
    let id: String
    let name: String
    let genres: String
  }

  struct SearchAlbum: Codable {
    let id: String
    let name: String
    let artists: String
  }
}

struct AlbumResponse: Codable {
  let id: String
  let name: String
  let artists: [Artist]
  let releaseDate: String
  let totalTracks: Int
  let label: String
  let popularity: Int
  let tracks: [Track]

  struct Artist: Codable {
    let id: String
    let name: String
  }

  struct Track: Codable {
    let id: String
    let name: String
    let trackNumber: Int
    let durationMs: Int
  }
}

import Foundation

/// Shared Spotify Web API limits used across services to avoid magic numbers.
enum SpotifyAPILimits {

  enum Pagination {
    /// Default limit range for most paginated endpoints (1...50).
    static let standardLimitRange: ClosedRange<Int> = 1...50
  }

  enum Albums {
    /// Maximum album IDs per request for catalog and library operations.
    static let batchSize = 20
  }

  enum Artists {
    /// Maximum artist IDs per request for catalog operations.
    static let batchSize = 50
  }

  enum Audiobooks {
    /// Maximum audiobook IDs per request for catalog operations.
    static let batchSize = 50
  }

  enum Chapters {
    /// Maximum chapter IDs per request for catalog operations.
    static let batchSize = 50
  }

  enum Episodes {
    /// Maximum episode IDs per request for catalog and library operations.
    static let batchSize = 50
  }

  enum Shows {
    /// Maximum show IDs per request for catalog and library operations.
    static let batchSize = 50
  }

  enum Tracks {
    /// Maximum track IDs per catalog request (e.g., `GET /tracks`).
    static let catalogBatchSize = 50

    /// Maximum track IDs per library save/remove request.
    static let libraryBatchSize = 50
  }

  enum Playlists {
    /// Maximum URIs that can be added, removed, or replaced in one request.
    static let itemMutationBatchSize = 100

    /// Maximum positions that can be removed in a single request.
    static let positionMutationBatchSize = 100
  }

  enum Users {
    /// Maximum artist/user IDs per follow/unfollow/check call.
    static let followBatchSize = 50

    /// Maximum user IDs when checking playlist followers.
    static let playlistFollowerCheckBatchSize = 5
  }

  enum Search {
    /// Maximum results per type supported by Spotify search.
    static let maxLimitPerType = 50
  }
}

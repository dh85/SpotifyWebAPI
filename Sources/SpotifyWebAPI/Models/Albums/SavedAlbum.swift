import Foundation

/// A Saved Album Object (from user's library).
///
/// Source: `GET /v1/me/albums`
public struct SavedAlbum: Codable, Sendable, Equatable {
  /// The date and time the album was saved.
  public let addedAt: Date

  /// Information about the album.
  public let album: Album
}

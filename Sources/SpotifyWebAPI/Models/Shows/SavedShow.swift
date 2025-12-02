import Foundation

/// A Saved Show Object (from user's library).
///
/// Source: `GET /v1/me/shows`
public struct SavedShow: Codable, Sendable, Equatable {
  /// The date and time the show was saved.
  public let addedAt: Date

  /// Information about the show.
  /// Note: This is a 'SimplifiedShow' (excludes episodes list).
  public let show: SimplifiedShow
}

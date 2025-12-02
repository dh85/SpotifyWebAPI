import Foundation

/// A Cursor-based Paging Object.
///
/// Used by endpoints like "Get Recently Played Tracks."
public struct CursorBasedPage<Item: Codable & Sendable & Equatable>: Codable,
  Sendable, Equatable
{
  /// A link to the Web API endpoint returning the full result.
  public let href: URL

  /// The array of items.
  public let items: [Item]

  /// The maximum number of items in the response.
  public let limit: Int

  /// URL to the next page of items. (Contains the 'after' cursor).
  public let next: URL?

  /// The cursors used to navigate.
  public let cursors: Cursors

  public struct Cursors: Codable, Sendable, Equatable, Hashable {
    /// The cursor to use as 'after' to get the next page.
    public let after: String?

    /// The cursor to use as 'before' to get the previous page.
    public let before: String?
  }
}

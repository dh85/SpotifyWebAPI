import Foundation

/// Shared interface for Spotify paging payloads.
public protocol PagingContainer {
  associatedtype Item
  var href: URL { get }
  var items: [Item] { get }
  var limit: Int { get }
  var next: URL? { get }
}

extension PagingContainer {
  public var hasMore: Bool { next != nil }
}

public protocol OffsetPagingContainer: PagingContainer {
  var offset: Int { get }
  var previous: URL? { get }
  var total: Int { get }
}

extension OffsetPagingContainer {
  public var hasPrevious: Bool { previous != nil }
}

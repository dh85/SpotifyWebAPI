import Foundation

/// Generic paging container used across Spotify Web API endpoints.
///
/// Represents a page of items with pagination metadata. Conforms to Equatable only when the generic item does.
///
/// [Spotify API Reference](https://developer.spotify.com/documentation/web-api/concepts/api-calls#pagination)
public struct Page<Item: Codable & Sendable & Equatable>: Codable, Sendable,
    Equatable
{
    /// The API endpoint URL that returned this page.
    public let href: URL
    /// The array of items in this page.
    public let items: [Item]
    /// The maximum number of items in the response (as set in the query or by default).
    public let limit: Int
    /// URL to the next page of items (nil if this is the last page).
    public let next: URL?
    /// The offset of the items returned (as set in the query or by default).
    public let offset: Int
    /// URL to the previous page of items (nil if this is the first page).
    public let previous: URL?
    /// The total number of items available to return.
    public let total: Int
}

extension Page: OffsetPagingContainer {}

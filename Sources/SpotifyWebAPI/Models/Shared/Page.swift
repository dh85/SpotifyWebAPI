import Foundation

/// Generic paging container used across Spotify Web API endpoints.
/// Conforms to Equatable **only when the generic item does**.
public struct Page<Item: Codable & Sendable & Equatable>: Codable, Sendable,
    Equatable
{
    public let href: URL
    public let items: [Item]
    public let limit: Int
    public let next: URL?
    public let offset: Int
    public let previous: URL?
    public let total: Int
}

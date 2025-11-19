import Foundation

/// Build a single `ids` query item from a set of IDs, sorted for determinism.
func makeIDsQueryItem(from ids: Set<String>) -> URLQueryItem {
    let sortedIDs = ids.sorted()
    return .init(name: "ids", value: sortedIDs.joined(separator: ","))
}

/// Build query items for an optional market code.
func makeMarketQueryItems(from market: String?) -> [URLQueryItem] {
    guard let market else { return [] }
    return [.init(name: "market", value: market)]
}

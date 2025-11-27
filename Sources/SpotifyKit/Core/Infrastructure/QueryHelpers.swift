import Foundation

// MARK: - Query Helpers

/// Build pagination query items.
func makePaginationQuery(limit: Int, offset: Int) -> [URLQueryItem] {
    [
        .init(name: "limit", value: String(limit)),
        .init(name: "offset", value: String(offset)),
    ]
}

/// Build a single `ids` query item from a set of IDs.
func makeIDsQueryItem(from ids: Set<String>) -> URLQueryItem {
    return .init(name: "ids", value: ids.joined(separator: ","))
}

/// Build query items for an optional market code.
func makeMarketQueryItems(from market: String?) -> [URLQueryItem] {
    guard let market else { return [] }
    return [.init(name: "market", value: market)]
}

/// Build query items with pagination and optional market.
func makePagedMarketQuery(limit: Int, offset: Int, market: String?) throws -> [URLQueryItem] {
    try buildPaginationQuery(limit: limit, offset: offset) + makeMarketQueryItems(from: market)
}

/// Build query items for pagination.
func buildPaginationQuery(limit: Int, offset: Int, validate: Bool = true) throws -> [URLQueryItem] {
    if validate { try validateLimit(limit) }
    return makePaginationQuery(limit: limit, offset: offset)
}

/// Convenience builder for assembling query items with optional parameters.
struct QueryBuilder: Sendable {
    private var items: [URLQueryItem]

    init(_ items: [URLQueryItem] = []) {
        self.items = items
    }

    /// Returns the assembled query items.
    func build() -> [URLQueryItem] {
        items
    }

    /// Adds raw query items.
    func adding(_ items: [URLQueryItem]) -> QueryBuilder {
        guard !items.isEmpty else { return self }
        var copy = self
        copy.items.append(contentsOf: items)
        return copy
    }

    /// Adds a single query item when the value is present.
    func adding(name: String, value: String?) -> QueryBuilder {
        guard let value else { return self }
        return adding([URLQueryItem(name: name, value: value)])
    }

    /// Adds a lossless string convertible value (e.g., Int, Bool) when present.
    func adding<T: LosslessStringConvertible>(name: String, value: T?) -> QueryBuilder {
        guard let value else { return self }
        return adding(name: name, value: String(value))
    }

    /// Adds pagination query items with optional validation.
    func addingPagination(limit: Int, offset: Int, validate: Bool = true) throws -> QueryBuilder {
        try adding(buildPaginationQuery(limit: limit, offset: offset, validate: validate))
    }
}

extension QueryBuilder {
    func addingMarket(_ market: String?) -> QueryBuilder {
        adding(name: "market", value: market)
    }

    func addingCountry(_ country: String?) -> QueryBuilder {
        adding(name: "country", value: country)
    }

    func addingLocale(_ locale: String?) -> QueryBuilder {
        adding(name: "locale", value: locale)
    }

    func addingFields(_ fields: String?) -> QueryBuilder {
        adding(name: "fields", value: fields)
    }

    func addingAdditionalTypes(_ types: Set<AdditionalItemType>?) -> QueryBuilder {
        guard let types, !types.isEmpty else { return self }
        return adding(name: "additional_types", value: types.spotifyQueryValue)
    }
}

import Foundation

// MARK: - Query Helpers

/// Build pagination query items.
func makePaginationQuery(limit: Int, offset: Int) -> [URLQueryItem] {
  [
    .init(name: "limit", value: String(limit)),
    .init(name: "offset", value: String(offset)),
  ]
}

/// Build a single `ids` query item from a set of IDs, sorted for determinism.
func makeIDsQueryItem(from ids: Set<String>) -> URLQueryItem {
  return .init(name: "ids", value: ids.joined(separator: ","))
}

/// Build query items for an optional market code.
func makeMarketQueryItems(from market: String?) -> [URLQueryItem] {
  guard let market else { return [] }
  return [.init(name: "market", value: market)]
}

/// Build query items with pagination and optional market.
func makePagedMarketQuery(limit: Int, offset: Int, market: String?) -> [URLQueryItem] {
  makePaginationQuery(limit: limit, offset: offset) + makeMarketQueryItems(from: market)
}

// MARK: - Date Helpers

/// Convert Date to Unix timestamp in milliseconds.
func dateToUnixMilliseconds(_ date: Date) -> Int64 {
  Int64(date.timeIntervalSince1970 * 1000)
}

/// Convert Unix timestamp in milliseconds to Date.
func dateFromUnixMilliseconds(_ milliseconds: Int64) -> Date {
  Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
}

// MARK: - Library Operation Helpers

/// Perform a library operation (save/remove) for a given endpoint.
func performLibraryOperation<Capability: Sendable>(
  _ method: HTTPMethod,
  endpoint: String,
  ids: Set<String>,
  client: SpotifyClient<Capability>
) async throws {
  let request: SpotifyRequest<EmptyResponse>
  switch method {
  case .put:
    request = .put(endpoint, body: IDsBody(ids: ids))
  case .delete:
    request = .delete(endpoint, body: IDsBody(ids: ids))
  default:
    throw SpotifyClientError.invalidRequest(reason: "Unsupported HTTP method: \(method)")
  }
  try await client.perform(request)
}

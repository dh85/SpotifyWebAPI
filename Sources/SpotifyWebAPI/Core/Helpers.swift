import Foundation

/// Build a single `ids` query item from a set of IDs, sorted for determinism.
func makeIDsQueryItem(from ids: Set<String>) -> URLQueryItem {
    return .init(name: "ids", value: ids.joined(separator: ","))
}

/// Build query items for an optional market code.
func makeMarketQueryItems(from market: String?) -> [URLQueryItem] {
    guard let market else { return [] }
    return [.init(name: "market", value: market)]
}

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

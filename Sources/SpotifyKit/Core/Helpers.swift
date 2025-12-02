import Foundation

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
    throw SpotifyClientError.invalidRequest(
      reason: "Unsupported HTTP method: \(method.rawValue)")
  }
  try await client.perform(request)
}

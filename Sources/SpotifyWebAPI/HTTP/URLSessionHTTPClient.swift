import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Default HTTP client backed by URLSession.
public struct URLSessionHTTPClient: HTTPClient {
  private let session: URLSession

  public init(session: URLSession = .shared) {
    self.session = session
  }

  public func data(for request: URLRequest) async throws -> (
    Data, URLResponse
  ) {
    try await session.data(for: request)
  }
}

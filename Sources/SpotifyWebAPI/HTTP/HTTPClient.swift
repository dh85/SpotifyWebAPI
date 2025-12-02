import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Transport-level abstraction so you can stub or swap the HTTP layer.
///
/// The default implementation uses URLSession.
public protocol HTTPClient: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

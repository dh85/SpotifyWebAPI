import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite
struct URLSessionHTTPClientTests {

  @Test
  func init_usesEphemeralSessionByDefault() {
    let client = URLSessionHTTPClient()
    let session = extractSession(from: client)

    #expect(session !== URLSession.shared)
  }

  @Test
  func init_acceptsCustomSession() {
    let session = URLSession.shared
    let client = URLSessionHTTPClient(session: session)

    // Verify client was created with custom session
    let _: HTTPClient = client
  }

  @Test
  func conformsToHTTPClient() {
    let client = URLSessionHTTPClient()
    let _: any HTTPClient = client
  }

  @Test
  func isSendable() {
    let _: any Sendable.Type = URLSessionHTTPClient.self
  }

  @Test
  func data_delegatesToURLSession() async throws {
    let url = URL(string: "https://delegation.test")!
    let client = makeClient()
    MockURLProtocol.setHandler(for: url) { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let data = "test data".data(using: .utf8)!
      return (response, data)
    }

    let response = try await client.data(for: URLRequest(url: url))

    #expect(String(data: response.data, encoding: .utf8) == "test data")
    #expect(response.statusCode == 200)
  }

  @Test
  func data_propagatesURLSessionErrors() async {
    let url = URL(string: "https://errors.test")!
    let client = makeClient()
    MockURLProtocol.setHandler(for: url) { _ in
      throw URLError(.notConnectedToInternet)
    }

    await #expect(throws: URLError.self) {
      _ = try await client.data(for: URLRequest(url: url))
    }
  }

  @Test
  func data_preservesHTTPURLResponseMetadata() async throws {
    let url = URL(string: "https://headers.test")!
    let client = makeClient()
    MockURLProtocol.setHandler(for: url) { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 204,
        httpVersion: "HTTP/1.1",
        headerFields: ["X-Test": "value"]
      )!
      return (response, Data())
    }

    let response = try await client.data(for: URLRequest(url: url))

    #expect(response.statusCode == 204)
    #expect(response.headerFields?["X-Test"] as? String == "value")
    #expect(response.httpURLResponse?.url == url)
  }

  @Test
  func configurationInitializerAppliesSettings() {
    let config = URLSessionHTTPClientConfiguration(
      timeoutIntervalForRequest: 5,
      timeoutIntervalForResource: 10,
      allowsCellularAccess: false,
      cachePolicy: .returnCacheDataElseLoad,
      httpAdditionalHeaders: ["X-Test": "value"]
    )

    let client = URLSessionHTTPClient(configuration: config)
    let session = extractSession(from: client)
    let applied = session.configuration

    #expect(applied.timeoutIntervalForRequest == config.timeoutIntervalForRequest)
    #expect(applied.timeoutIntervalForResource == config.timeoutIntervalForResource)
    #expect(applied.allowsCellularAccess == config.allowsCellularAccess)
    #expect(applied.requestCachePolicy == config.cachePolicy)
    #expect(applied.httpAdditionalHeaders?["X-Test"] as? String == "value")
  }

  @Test
  func configurationInitializerUsesCustomHeadersInRequests() async throws {
    let config = URLSessionHTTPClientConfiguration(
      timeoutIntervalForRequest: 5,
      timeoutIntervalForResource: 10,
      allowsCellularAccess: false,
      cachePolicy: .returnCacheDataElseLoad,
      httpAdditionalHeaders: ["X-Test": "value"]
    )
    let configurationBox = ConfigurationBox()

    let client = URLSessionHTTPClient(configuration: config) { configuration, queue in
      configurationBox.configuration = configuration
      configuration.protocolClasses = [MockURLProtocol.self]
      return URLSession(configuration: configuration, delegate: nil, delegateQueue: queue)
    }

    let url = URL(string: "https://configured.test")!
    var handlerCalled = false
    MockURLProtocol.setHandler(for: url) { request in
      handlerCalled = true
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: "HTTP/2",
        headerFields: nil
      )!
      return (response, Data())
    }

    let response = try await client.data(for: URLRequest(url: url))
    #expect(response.statusCode == 200)
    #expect(handlerCalled)
    #expect(
      configurationBox.configuration?.httpAdditionalHeaders?["X-Test"] as? String == "value")
    #expect(configurationBox.configuration?.requestCachePolicy == config.cachePolicy)
    #expect(
      configurationBox.configuration?.protocolClasses?.contains(where: {
        $0 == MockURLProtocol.self
      }) == true)
  }

  @Test
  func pinnedCertificateLoadsFromFileURL() throws {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    let certificateData = Data([0x01, 0x02, 0x03])
    try certificateData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let certificate = try URLSessionHTTPClient.PinnedCertificate(fileURL: tempURL)
    #expect(certificate.data == certificateData)
  }

  @Test
  func pinnedCertificateResourceInitializerThrowsWhenMissing() {
    #expect(throws: URLSessionHTTPClientPinningError.self) {
      _ = try URLSessionHTTPClient.PinnedCertificate(
        resource: "missing_cert", fileExtension: "der")
    }
  }

  #if canImport(Security)
    @Test
    func makePinnedSessionThrowsWithoutCertificates() {
      #expect(throws: URLSessionHTTPClientPinningError.self) {
        _ = try URLSessionHTTPClient.makePinnedSession(pinnedCertificates: [])
      }
    }
  #endif
}

// MARK: - Helpers

private func makeClient() -> URLSessionHTTPClient {
  let config = URLSessionConfiguration.ephemeral
  config.protocolClasses = [MockURLProtocol.self]
  let session = URLSession(configuration: config)
  return URLSessionHTTPClient(session: session)
}

private func extractSession(from client: URLSessionHTTPClient) -> URLSession {
  let mirror = Mirror(reflecting: client)
  for child in mirror.children {
    if let session = child.value as? URLSession {
      return session
    }
  }
  fatalError("URLSessionHTTPClient no longer stores session in accessible layout")
}

private final class ConfigurationBox: @unchecked Sendable {
  var configuration: URLSessionConfiguration?
}

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol {
  typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

  private final class HandlerStore: @unchecked Sendable {
    private var handlers: [URL: Handler] = [:]
    private let lock = NSLock()

    func set(_ handler: Handler?, for url: URL) {
      lock.lock()
      handlers[url] = handler
      lock.unlock()
    }

    func handler(for url: URL) -> Handler? {
      lock.lock()
      let handler = handlers[url]
      lock.unlock()
      return handler
    }
  }

  private static let handlerStore = HandlerStore()

  static func setHandler(for url: URL, handler: Handler?) {
    handlerStore.set(handler, for: url)
  }

  private static func handler(for url: URL) -> Handler? {
    handlerStore.handler(for: url)
  }

  override class func canInit(with request: URLRequest) -> Bool {
    guard let url = request.url else { return false }
    return handlerStore.handler(for: url) != nil
  }

  override class func canInit(with task: URLSessionTask) -> Bool {
    guard let url = task.currentRequest?.url else { return false }
    return handlerStore.handler(for: url) != nil
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard
      let url = request.url,
      let handler = Self.handler(for: url)
    else {
      fatalError("Handler unavailable for \(String(describing: request.url)).")
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {
    guard let url = request.url else { return }
    Self.handlerStore.set(nil, for: url)
  }
}

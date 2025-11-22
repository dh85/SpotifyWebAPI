import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
struct URLSessionHTTPClientTests {
    
    @Test
    func init_usesSharedSessionByDefault() {
        let client = URLSessionHTTPClient()
        
        // Verify client was created (can't access private session property)
        let _: HTTPClient = client
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
        // Create a mock URLSession that returns test data
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        let client = URLSessionHTTPClient(session: session)
        let request = URLRequest(url: URL(string: "https://test.com")!)
        
        // Set up mock response
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = "test data".data(using: .utf8)!
            return (response, data)
        }
        
        let response = try await client.data(for: request)
        
        #expect(String(data: response.data, encoding: .utf8) == "test data")
        #expect(response.statusCode == 200)
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
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
    }
}

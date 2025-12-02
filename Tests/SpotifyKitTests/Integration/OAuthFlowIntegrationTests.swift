import Crypto
import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("OAuth Flow Integration Tests")
struct OAuthFlowIntegrationTests {

  // MARK: - PKCE Flow Tests

  @Test("PKCE flow completes successfully with S256 challenge")
  func pkceFlowWithS256CompletesSuccessfully() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-pkce-client",
        clientSecret: "test-secret",
        enablePKCE: true,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      // 1. Generate PKCE parameters
      let codeVerifier = generateCodeVerifier()
      let codeChallenge = generateS256Challenge(from: codeVerifier)

      // 2. Simulate authorization request
      let state = "random-state-123"
      let redirectURI = "myapp://callback"
      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-pkce-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code&code_challenge=\(codeChallenge)&code_challenge_method=S256&scope=user-read-email"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)
      #expect(!authCode.isEmpty)

      // 3. Exchange authorization code for tokens
      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: codeVerifier,
        clientID: nil,
        clientSecret: nil
      )

      let tokens = try await exchangeCodeForTokens(
        tokenEndpoint: info.tokenEndpoint.absoluteString,
        request: tokenRequest
      )

      #expect(!tokens.accessToken.isEmpty)
      #expect(tokens.refreshToken != nil)
      #expect(tokens.tokenType == "Bearer")
      #expect(tokens.expiresIn == 3600)
    }
  }

  @Test("PKCE flow with plain challenge method")
  func pkceFlowWithPlainChallenge() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-client",
        clientSecret: "test-secret",
        enablePKCE: true,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let codeVerifier = "plain-verifier-123"
      let codeChallenge = codeVerifier  // plain method
      let state = "state-456"
      let redirectURI = "myapp://callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code&code_challenge=\(codeChallenge)&code_challenge_method=plain"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: codeVerifier,
        clientID: nil,
        clientSecret: nil
      )

      let tokens = try await exchangeCodeForTokens(
        tokenEndpoint: info.tokenEndpoint.absoluteString,
        request: tokenRequest
      )

      #expect(!tokens.accessToken.isEmpty)
      #expect(tokens.refreshToken != nil)
    }
  }

  @Test("PKCE flow fails with invalid code verifier")
  func pkceFlowFailsWithInvalidVerifier() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-client",
        clientSecret: "test-secret",
        enablePKCE: true,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let codeVerifier = generateCodeVerifier()
      let codeChallenge = generateS256Challenge(from: codeVerifier)
      let state = "state-789"
      let redirectURI = "myapp://callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code&code_challenge=\(codeChallenge)&code_challenge_method=S256"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      // Use wrong verifier
      let wrongVerifier = "wrong-verifier"
      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: wrongVerifier,
        clientID: nil,
        clientSecret: nil
      )

      await #expect(throws: Error.self) {
        try await exchangeCodeForTokens(
          tokenEndpoint: info.tokenEndpoint.absoluteString,
          request: tokenRequest
        )
      }
    }
  }

  // MARK: - Authorization Code Flow Tests

  @Test("Standard authorization code flow with client secret")
  func standardAuthorizationCodeFlow() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "standard-client",
        clientSecret: "standard-secret",
        enablePKCE: false,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let state = "state-abc"
      let redirectURI = "https://myapp.com/callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=standard-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code&scope=playlist-modify-private"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: nil,
        clientID: "standard-client",
        clientSecret: "standard-secret"
      )

      let tokens = try await exchangeCodeForTokens(
        tokenEndpoint: info.tokenEndpoint.absoluteString,
        request: tokenRequest
      )

      #expect(!tokens.accessToken.isEmpty)
      #expect(tokens.refreshToken != nil)
      #expect(tokens.scope == "playlist-modify-private")
    }
  }

  @Test("Authorization code flow fails with invalid client credentials")
  func authCodeFlowFailsWithInvalidCredentials() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "valid-client",
        clientSecret: "valid-secret",
        enablePKCE: false,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let state = "state-def"
      let redirectURI = "https://myapp.com/callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=valid-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: nil,
        clientID: "valid-client",
        clientSecret: "wrong-secret"  // Invalid secret
      )

      await #expect(throws: Error.self) {
        try await exchangeCodeForTokens(
          tokenEndpoint: info.tokenEndpoint.absoluteString,
          request: tokenRequest
        )
      }
    }
  }

  @Test("Authorization fails with mismatched redirect URI")
  func authFlowFailsWithMismatchedRedirectURI() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-client",
        clientSecret: "test-secret",
        enablePKCE: false,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let state = "state-ghi"
      let redirectURI = "https://myapp.com/callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      // Use different redirect URI in token exchange
      let tokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: "https://different.com/callback",  // Mismatched
        codeVerifier: nil,
        clientID: "test-client",
        clientSecret: "test-secret"
      )

      await #expect(throws: Error.self) {
        try await exchangeCodeForTokens(
          tokenEndpoint: info.tokenEndpoint.absoluteString,
          request: tokenRequest
        )
      }
    }
  }

  // MARK: - Refresh Token Tests

  @Test("Refresh token rotates access token successfully")
  func refreshTokenRotatesAccessToken() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-client",
        clientSecret: "test-secret",
        enablePKCE: true,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      // First, get tokens via PKCE
      let codeVerifier = generateCodeVerifier()
      let codeChallenge = generateS256Challenge(from: codeVerifier)
      let state = "state-refresh"
      let redirectURI = "myapp://callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code&code_challenge=\(codeChallenge)&code_challenge_method=S256"

      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)

      let initialTokenRequest = TokenExchangeRequest(
        grantType: "authorization_code",
        code: authCode,
        redirectURI: redirectURI,
        codeVerifier: codeVerifier,
        clientID: nil,
        clientSecret: nil
      )

      let initialTokens = try await exchangeCodeForTokens(
        tokenEndpoint: info.tokenEndpoint.absoluteString,
        request: initialTokenRequest
      )

      guard let refreshToken = initialTokens.refreshToken else {
        throw TestError.missingRefreshToken
      }

      // Now refresh the access token
      let refreshRequest = TokenRefreshRequest(
        grantType: "refresh_token",
        refreshToken: refreshToken
      )

      let newTokens = try await refreshAccessToken(
        tokenEndpoint: info.tokenEndpoint.absoluteString,
        request: refreshRequest
      )

      #expect(!newTokens.accessToken.isEmpty)
      #expect(newTokens.accessToken != initialTokens.accessToken)
      #expect(newTokens.refreshToken == refreshToken)  // Same refresh token
    }
  }

  @Test("Refresh token request fails with invalid token")
  func refreshFailsWithInvalidToken() async throws {
    let server = SpotifyMockAPIServer()

    try await server.withRunningServer { info in
      let refreshRequest = TokenRefreshRequest(
        grantType: "refresh_token",
        refreshToken: "invalid-refresh-token"
      )

      await #expect(throws: Error.self) {
        try await refreshAccessToken(
          tokenEndpoint: info.tokenEndpoint.absoluteString,
          request: refreshRequest
        )
      }
    }
  }

  @Test("OAuth state parameter validates CSRF protection")
  func oauthStateParameterValidation() async throws {
    let config = SpotifyMockAPIServer.Configuration(
      oauthConfig: .init(
        clientID: "test-client",
        clientSecret: "test-secret",
        enablePKCE: false,
        enableAuthorizationCode: true,
        refreshTokenExpiry: 3600
      )
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let state = "expected-state-value"
      let redirectURI = "https://myapp.com/callback"

      let authorizeURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&state=\(state)&response_type=code"

      // Simulate authorization and verify state is returned
      let authCode = try await simulateAuthorization(url: authorizeURL, expectedState: state)
      #expect(!authCode.isEmpty)

      // Authorization without state should fail
      let noStateURL =
        "\(info.authorizeEndpoint.absoluteString)?client_id=test-client&redirect_uri=\(redirectURI)&response_type=code"

      await #expect(throws: Error.self) {
        _ = try await simulateAuthorization(url: noStateURL, expectedState: nil)
      }
    }
  }

  // MARK: - Helper Methods

  private func generateCodeVerifier() -> String {
    let length = 128
    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    return String((0..<length).map { _ in characters.randomElement()! })
  }

  private func generateS256Challenge(from verifier: String) -> String {
    guard let data = verifier.data(using: .utf8) else { return "" }
    let hash = Crypto.SHA256.hash(data: data)
    let base64 = Data(hash).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return base64
  }

  private func simulateAuthorization(url: String, expectedState: String?) async throws -> String {
    // Simulate HTTP GET to authorize endpoint
    guard let urlComponents = URLComponents(string: url),
      let host = urlComponents.host,
      let port = urlComponents.port
    else {
      throw TestError.invalidURL
    }

    let authorizeURL = URL(
      string: "http://\(host):\(port)\(urlComponents.path)?\(urlComponents.query ?? "")")!

    var request = URLRequest(url: authorizeURL)
    request.httpMethod = "GET"

    // Create a session that doesn't follow redirects
    let config = URLSessionConfiguration.ephemeral
    let session = URLSession(
      configuration: config, delegate: NoRedirectDelegate(), delegateQueue: nil)

    let (_, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw TestError.invalidResponse
    }

    // Check for error responses
    guard httpResponse.statusCode == 302 else {
      throw TestError.httpError(httpResponse.statusCode)
    }

    guard let location = httpResponse.value(forHTTPHeaderField: "Location"),
      let redirectURL = URLComponents(string: location)
    else {
      throw TestError.missingLocation
    }

    // Extract code and state from redirect
    guard let code = redirectURL.queryItems?.first(where: { $0.name == "code" })?.value else {
      throw TestError.missingAuthCode
    }

    if let expectedState = expectedState {
      let returnedState = redirectURL.queryItems?.first(where: { $0.name == "state" })?.value
      #expect(returnedState == expectedState)
    }

    return code
  }

  // URLSession delegate to prevent following redirects
  private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
      _ session: URLSession,
      task: URLSessionTask,
      willPerformHTTPRedirection response: HTTPURLResponse,
      newRequest request: URLRequest,
      completionHandler: @escaping (URLRequest?) -> Void
    ) {
      // Don't follow redirects
      completionHandler(nil)
    }
  }

  private func exchangeCodeForTokens(
    tokenEndpoint: String,
    request: TokenExchangeRequest
  ) async throws -> TokenResponse {
    let url = URL(string: tokenEndpoint)!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    var params: [String: String] = [
      "grant_type": request.grantType,
      "code": request.code,
      "redirect_uri": request.redirectURI,
    ]

    if let verifier = request.codeVerifier {
      params["code_verifier"] = verifier
    }

    if let clientID = request.clientID {
      params["client_id"] = clientID
    }

    if let clientSecret = request.clientSecret {
      params["client_secret"] = clientSecret
    }

    let body = params.map {
      "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)"
    }.joined(separator: "&")
    urlRequest.httpBody = body.data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw TestError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw TestError.httpError(httpResponse.statusCode)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(TokenResponse.self, from: data)
  }

  private func refreshAccessToken(
    tokenEndpoint: String,
    request: TokenRefreshRequest
  ) async throws -> TokenResponse {
    let url = URL(string: tokenEndpoint)!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let body = "grant_type=\(request.grantType)&refresh_token=\(request.refreshToken)"
    urlRequest.httpBody = body.data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw TestError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw TestError.httpError(httpResponse.statusCode)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(TokenResponse.self, from: data)
  }

  // MARK: - Supporting Types

  struct TokenExchangeRequest {
    let grantType: String
    let code: String
    let redirectURI: String
    let codeVerifier: String?
    let clientID: String?
    let clientSecret: String?
  }

  struct TokenRefreshRequest {
    let grantType: String
    let refreshToken: String
  }

  struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String
  }

  enum TestError: Error {
    case invalidURL
    case invalidResponse
    case missingLocation
    case missingAuthCode
    case missingRefreshToken
    case httpError(Int)
  }
}

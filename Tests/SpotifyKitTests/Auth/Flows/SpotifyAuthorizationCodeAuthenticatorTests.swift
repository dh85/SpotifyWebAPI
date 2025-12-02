import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct SpotifyAuthorizationCodeAuthenticatorTests {

  // MARK: - Shared helpers

  private func expectHandleCallback(
    url: URL,
    expectedError: SpotifyAuthError,
    preloadAuthorization: Bool = true
  ) async {

    let harness = AuthenticatorTestHarness.makeHarness()
    let auth = harness.makeAuthorizationCodeAuthenticator()

    if preloadAuthorization {
      _ = try? await auth.makeAuthorizationURL()
    }

    await #expect(throws: expectedError) {
      _ = try await auth.handleCallback(url)
    }
  }

  // MARK: - makeAuthorizationURL

  @Test
  func makeAuthorizationURL_buildsCorrectQuery() async throws {
    let harness = AuthenticatorTestHarness.makeHarness()
    let auth = harness.makeAuthorizationCodeAuthenticator()

    let url = try await auth.makeAuthorizationURL()

    #expect(AuthTestFixtures.queryValue(from: url, name: "client_id") == "TEST_CLIENT_ID")
    #expect(AuthTestFixtures.queryValue(from: url, name: "response_type") == "code")
    #expect(AuthTestFixtures.queryValue(from: url, name: "redirect_uri") == "myapp://callback")
    #expect(AuthTestFixtures.queryValue(from: url, name: "state") != nil)

    let scope = AuthTestFixtures.queryValue(from: url, name: "scope")
    #expect(
      scope == "playlist-read-private user-read-email"
        || scope == "user-read-email playlist-read-private"
    )
    #expect(AuthTestFixtures.queryValue(from: url, name: "show_dialog") == "true")

    // Check state looks like our generateState output: no '-'
    let state = AuthTestFixtures.queryValue(from: url, name: "state")!
    #expect(!state.contains("-"))
  }

  // MARK: - handleCallback success and error paths

  @Test
  func handleCallback_successExchangesCodeAndPersists() async throws {
    let tokenJSON = AuthTestFixtures.tokenResponse(
      accessToken: "ACCESS123",
      refreshToken: "REFRESH123"
    )

    let harness = AuthenticatorTestHarness.makeHarness(
      response: .success(data: tokenJSON, statusCode: 200)
    )
    let auth = harness.makeAuthorizationCodeAuthenticator()

    let url = try await auth.makeAuthorizationURL()
    let state =
      URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first(where: { $0.name == "state" })?
      .value ?? ""

    let callback = URL(
      string: "myapp://callback?code=AUTH_CODE&state=\(state)"
    )!

    let tokens = try await auth.handleCallback(callback)

    #expect(tokens.accessToken == "ACCESS123")
    #expect(tokens.refreshToken == "REFRESH123")
    #expect(tokens.tokenType == "Bearer")

    // Persisted
    let stored = try await harness.tokenStore.load()
    #expect(stored?.accessToken == "ACCESS123")
  }

  @Test
  func handleCallback_componentsBuilderNilThrowsMissingCode() async {
    let harness = AuthenticatorTestHarness.makeHarness()
    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: harness.httpClient,
      tokenStore: harness.tokenStore,
      componentsBuilder: { _ in nil }
    )

    let callback = URL(string: "myapp://callback?code=AUTH&state=S")!

    await #expect(throws: SpotifyAuthError.missingCode) {
      _ = try await auth.handleCallback(callback)
    }
  }

  @Test
  func handleCallback_noQueryItemsTriggersNilQueryItemsBranch() async {
    // No `?` → queryItems == nil → [] and then missingCode
    let callback = AuthTestFixtures.callbackURL()

    await expectHandleCallback(
      url: callback,
      expectedError: .missingCode,
      preloadAuthorization: false
    )
  }

  @Test
  func handleCallback_missingCodeThrows() async {
    let callback = AuthTestFixtures.callbackURL(state: "STATE123")

    await expectHandleCallback(
      url: callback,
      expectedError: .missingCode,
      preloadAuthorization: false
    )
  }

  @Test
  func handleCallback_missingStateThrows() async {
    let callback = AuthTestFixtures.callbackURL(code: "AUTH_CODE")

    await expectHandleCallback(
      url: callback,
      expectedError: .missingState
    )
  }

  @Test
  func handleCallback_stateMismatchThrows() async {
    let callback = AuthTestFixtures.callbackURL(
      code: "AUTH_CODE",
      state: "OTHER"
    )

    await expectHandleCallback(
      url: callback,
      expectedError: .stateMismatch
    )
  }

  @Test
  func handleCallback_throwsWhenClientSecretMissing() async {
    let pkceConfig = AuthTestFixtures.pkceConfig()
    let harness = AuthenticatorTestHarness.makeHarness(
      response: .success(
        data: AuthTestFixtures.tokenResponse(accessToken: "TOKEN"),
        statusCode: 200
      )
    )
    let auth = harness.makeAuthorizationCodeAuthenticator(config: pkceConfig)

    let authURL = try! await auth.makeAuthorizationURL()
    let state =
      URLComponents(url: authURL, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first(where: { $0.name == "state" })?
      .value ?? ""

    let callback = URL(string: "pkce://callback?code=AUTH&state=\(state)")!

    await #expect(throws: SpotifyAuthError.unexpectedResponse) {
      _ = try await auth.handleCallback(callback)
    }
  }

  // MARK: - formURLEncodedBody via debug helper

  @Test
  func formURLEncodedBody_nilPercentEncodedQueryWhenItemsEmpty() async throws {
    // Empty items → percentEncodedQuery == nil → "" used
    let data = __test_formURLEncodedBody(items: [])
    let string = String(data: data, encoding: .utf8)

    #expect(string == "")
  }

  // MARK: - loadPersistedTokens

  @Test
  func loadPersistedTokens_usesCacheOnSecondCall() async throws {
    let tokens = SpotifyTokens(
      accessToken: "ACCESS",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let store = InMemoryTokenStore(tokens: tokens)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: SimpleMockHTTPClient(
        response: .success(data: Data(), statusCode: 200)
      ),
      tokenStore: store
    )

    let first = try await auth.loadPersistedTokens()
    let second = try await auth.loadPersistedTokens()

    #expect(first?.accessToken == "ACCESS")
    #expect(second?.accessToken == "ACCESS")
  }

  // MARK: - Missing client secret safeguards

  @Test
  func refreshAccessToken_throwsWhenClientSecretMissing() async {
    let pkceConfig = SpotifyAuthConfig.pkce(
      clientID: "PKCE_CLIENT",
      redirectURI: URL(string: "pkce://callback")!
    )

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: pkceConfig,
      httpClient: SimpleMockHTTPClient(
        response: .success(data: Data(), statusCode: 200)
      ),
      tokenStore: InMemoryTokenStore()
    )

    await #expect(throws: SpotifyAuthError.unexpectedResponse) {
      _ = try await auth.refreshAccessToken(refreshToken: "REFRESH")
    }
  }

  // MARK: - refreshAccessTokenIfNeeded branches

  @Test
  func refreshAccessTokenIfNeeded_usesCachedNotExpired() async throws {
    let tokens = SpotifyTokens(
      accessToken: "ACCESS",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let store = InMemoryTokenStore(tokens: tokens)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: SimpleMockHTTPClient(
        response: .success(data: Data(), statusCode: 200)
      ),
      tokenStore: store
    )

    // Populate cachedTokens
    _ = try await auth.loadPersistedTokens()

    let result = try await auth.refreshAccessTokenIfNeeded()
    #expect(result.accessToken == "ACCESS")
  }

  @Test
  func refreshAccessTokenIfNeeded_cachedExpiredWithRefresh() async throws {
    let expired = SpotifyTokens(
      accessToken: "OLD",
      refreshToken: "REFRESH_OLD",
      expiresAt: Date().addingTimeInterval(-3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let json = AuthTestFixtures.tokenResponse(
      accessToken: "NEW_ACCESS",
      refreshToken: nil  // ensure existingRefreshToken is used
    )

    let http = SimpleMockHTTPClient(
      response: .success(data: json, statusCode: 200)
    )

    let store = InMemoryTokenStore(tokens: expired)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: store
    )

    // cachedTokens = expired
    _ = try await auth.loadPersistedTokens()

    let refreshed = try await auth.refreshAccessTokenIfNeeded()

    #expect(refreshed.accessToken == "NEW_ACCESS")
    #expect(refreshed.refreshToken == "REFRESH_OLD")
  }

  @Test
  func refreshAccessTokenIfNeeded_loadsFromStoreNotExpired() async throws {
    let tokens = SpotifyTokens(
      accessToken: "ACCESS_STORE",
      refreshToken: "REFRESH_STORE",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let store = InMemoryTokenStore(tokens: tokens)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: SimpleMockHTTPClient(
        response: .success(data: Data(), statusCode: 200)
      ),
      tokenStore: store
    )

    // cachedTokens is nil, store has non-expired tokens
    let result = try await auth.refreshAccessTokenIfNeeded()

    #expect(result.accessToken == "ACCESS_STORE")
  }

  @Test
  func refreshAccessTokenIfNeeded_storeExpiredWithRefresh() async throws {
    let expired = SpotifyTokens(
      accessToken: "OLD_STORE",
      refreshToken: "REFRESH_STORE",
      expiresAt: Date().addingTimeInterval(-3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let json = AuthTestFixtures.tokenResponse(
      accessToken: "NEW_FROM_REFRESH",
      refreshToken: "REFRESH_NEW"
    )

    let http = SimpleMockHTTPClient(
      response: .success(data: json, statusCode: 200)
    )

    let store = InMemoryTokenStore(tokens: expired)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: store
    )

    let refreshed = try await auth.refreshAccessTokenIfNeeded()

    #expect(refreshed.accessToken == "NEW_FROM_REFRESH")
    #expect(refreshed.refreshToken == "REFRESH_NEW")
  }

  @Test
  func refreshAccessTokenIfNeeded_coalescesConcurrentRefreshes() async throws {
    let expired = SpotifyTokens(
      accessToken: "OLD_STORE",
      refreshToken: "REFRESH_STORE",
      expiresAt: Date().addingTimeInterval(-3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let json = AuthTestFixtures.tokenResponse(
      accessToken: "COALESCED_ACCESS",
      refreshToken: "COALESCED_REFRESH"
    )

    let http = SlowMockHTTPClient(
      responseData: json,
      delayNanoseconds: 100_000_000
    )

    let store = InMemoryTokenStore(tokens: expired)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: store
    )

    _ = try await auth.loadPersistedTokens()

    async let first = auth.refreshAccessTokenIfNeeded(invalidatingPrevious: true)
    async let second = auth.refreshAccessTokenIfNeeded(invalidatingPrevious: true)
    async let third = auth.refreshAccessTokenIfNeeded()

    let results = try await (first, second, third)

    #expect(results.0.accessToken == "COALESCED_ACCESS")
    #expect(results.1.accessToken == "COALESCED_ACCESS")
    #expect(results.2.accessToken == "COALESCED_ACCESS")
    #expect(results.0.refreshToken == "COALESCED_REFRESH")
    #expect(results.1.refreshToken == "COALESCED_REFRESH")
    #expect(results.2.refreshToken == "COALESCED_REFRESH")
    #expect(await http.recordedCallCount() == 1)
  }

  @Test
  func refreshAccessTokenIfNeeded_missingRefreshTokenThrows() async {
    let store = InMemoryTokenStore(tokens: nil)

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: SimpleMockHTTPClient(
        response: .success(data: Data(), statusCode: 200)
      ),
      tokenStore: store
    )

    await #expect(throws: SpotifyAuthError.missingRefreshToken) {
      _ = try await auth.refreshAccessTokenIfNeeded()
    }
  }

  // MARK: - refreshAccessToken direct

  @Test
  func
    refreshAccessToken_successUsesExistingRefreshTokenWhenMissingInResponse()
    async throws
  {
    let json = AuthTestFixtures.tokenResponse(
      accessToken: "NEW_ACCESS",
      refreshToken: nil
    )

    let http = SimpleMockHTTPClient(
      response: .success(data: json, statusCode: 200)
    )

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: InMemoryTokenStore()
    )

    let tokens = try await auth.refreshAccessToken(refreshToken: "REF_OLD")

    #expect(tokens.accessToken == "NEW_ACCESS")
    #expect(tokens.refreshToken == "REF_OLD")
  }

  @Test
  func refreshAccessToken_unexpectedResponseWhenNonHTTPURLResponse() async {
    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: NonHTTPResponseMockHTTPClient(),
      tokenStore: InMemoryTokenStore()
    )

    await #expect(throws: SpotifyAuthError.unexpectedResponse) {
      _ = try await auth.refreshAccessToken(refreshToken: "REF")
    }
  }

  @Test
  func refreshAccessToken_httpErrorWithUTF8Body() async {
    let http = StatusMockHTTPClient(statusCode: 400, body: "bad request")

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: InMemoryTokenStore()
    )

    await #expect(
      throws: SpotifyAuthError.httpError(
        statusCode: 400,
        body: "bad request"
      )
    ) {
      _ = try await auth.refreshAccessToken(refreshToken: "REF")
    }
  }

  @Test
  func refreshAccessToken_httpErrorWithNonUTF8BodyUsesFallbackString() async {
    // Deliberately invalid UTF-8 bytes
    let invalidData = Data([0xFF, 0xFF, 0xFF])

    let http = BinaryBodyMockHTTPClient(
      statusCode: 400,
      data: invalidData
    )

    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: AuthTestFixtures.authCodeConfig(),
      httpClient: http,
      tokenStore: InMemoryTokenStore()
    )

    await #expect(
      throws: SpotifyAuthError.httpError(
        statusCode: 400,
        body: "<non-utf8 body>"
      )
    ) {
      _ = try await auth.refreshAccessToken(refreshToken: "REF")
    }
  }
}

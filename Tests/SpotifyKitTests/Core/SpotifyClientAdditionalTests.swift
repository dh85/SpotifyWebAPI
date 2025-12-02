import Atomics
import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyClientAdditionalTests {

  @Test
  func addInterceptor_addsToInterceptorsList() async {
    let client = await makeTestClient()

    await client.addInterceptor { request in
      request
    }

    let count = await client.interceptors.count
    #expect(count == 1)
  }

  @Test
  func removeAllInterceptors_clearsInterceptorsList() async {
    let client = await makeTestClient()

    await client.addInterceptor { $0 }
    await client.addInterceptor { $0 }

    await client.removeAllInterceptors()

    let count = await client.interceptors.count
    #expect(count == 0)
  }

  @Test
  func tokenExpiresIn_returnsNilWhenNoTokenCached() async {
    let auth = FailingTokenAuthenticator()
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let expiresIn = await client.tokenExpiresIn()
    #expect(expiresIn == nil)
  }

  @Test
  func tokenExpiresIn_returnsTimeIntervalWhenTokenExists() async {
    let futureDate = Date().addingTimeInterval(3600)
    let token = SpotifyTokens(
      accessToken: "TOKEN",
      refreshToken: "REFRESH",
      expiresAt: futureDate,
      scope: nil,
      tokenType: "Bearer"
    )

    let auth = MockTokenAuthenticator(token: token)
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let expiresIn = await client.tokenExpiresIn()
    #expect(expiresIn != nil)
    #expect(expiresIn! > 3500)
    #expect(expiresIn! < 3700)
  }

  @Test
  func setOffline_updatesOfflineState() async {
    let client = await makeTestClient()

    await client.setOffline(true)
    let isOffline = await client.isOffline()
    #expect(isOffline == true)

    await client.setOffline(false)
    let isOnline = await client.isOffline()
    #expect(isOnline == false)
  }

  @Test
  func isOffline_defaultsToFalse() async {
    let client = await makeTestClient()
    let isOffline = await client.isOffline()
    #expect(isOffline == false)
  }

  @Test
  func builder_userClient_returnsBuilder() {
    let _: SpotifyUserClientBuilder = UserSpotifyClient.builder()
  }

  @Test
  func builder_appClient_returnsBuilder() {
    let _: SpotifyAppClientBuilder = AppSpotifyClient.builder()
  }

  @Test
  func userClientBuilder_withAuthorizationCode_configuresFlow() {
    let builder = SpotifyUserClientBuilder()
      .withAuthorizationCode(
        clientID: "test",
        clientSecret: "secret",
        redirectURI: URL(string: "test://callback")!,
        scopes: [.userReadEmail],
        showDialog: true
      )

    let _: UserSpotifyClient = builder.build()
  }

  @Test
  func appClientBuilder_withTokenStore_configuresStore() {
    let store = InMemoryTokenStore()
    let builder = AppSpotifyClient.builder()
      .withClientCredentials(clientID: "test", clientSecret: "secret")
      .withTokenStore(store)

    let _: AppSpotifyClient = builder.build()
  }

  @Test
  func accessToken_invokesTokenRefreshWillStartCallback() async throws {
    let expiredToken = SpotifyTokens(
      accessToken: "OLD_TOKEN",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(-100),
      scope: nil,
      tokenType: "Bearer"
    )

    let auth = MockTokenAuthenticator(token: expiredToken)
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let invoked = ManagedAtomic<Bool>(false)
    await client.events.onTokenRefreshWillStart { _ in
      invoked.store(true, ordering: .relaxed)
    }

    _ = try await client.accessToken()
    #expect(invoked.load(ordering: .relaxed) == true)
  }

  @Test
  func accessToken_invokesTokenRefreshDidSucceedCallback() async throws {
    let expiredToken = SpotifyTokens(
      accessToken: "OLD_TOKEN",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(-100),
      scope: nil,
      tokenType: "Bearer"
    )

    let auth = MockTokenAuthenticator(token: expiredToken)
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let invoked = ManagedAtomic<Bool>(false)
    await client.events.onTokenRefreshDidSucceed { _ in
      invoked.store(true, ordering: .relaxed)
    }

    _ = try await client.accessToken()
    #expect(invoked.load(ordering: .relaxed) == true)
  }

  @Test
  func accessToken_invokesTokenRefreshDidFailCallbackOnError() async throws {
    // Create a failing authenticator
    let auth = FailingTokenAuthenticator()
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let invoked = ManagedAtomic<Bool>(false)
    await client.events.onTokenRefreshDidFail { _ in
      invoked.store(true, ordering: .relaxed)
    }

    do {
      _ = try await client.accessToken()
      Issue.record("Expected error to be thrown")
    } catch {
      #expect(invoked.load(ordering: .relaxed) == true)
    }
  }

  @Test
  func accessToken_invokesTokenExpiringCallback() async throws {
    let token = SpotifyTokens(
      accessToken: "TOKEN",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let auth = MockTokenAuthenticator(token: token)
    let client = SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )

    let invoked = ManagedAtomic<Bool>(false)
    await client.events.onTokenExpiring { _ in
      invoked.store(true, ordering: .relaxed)
    }

    _ = try await client.accessToken()
    #expect(invoked.load(ordering: .relaxed) == true)
  }

  @Test
  func addObserver_returnsToken() async {
    let client = await makeTestClient()
    let observer = TestObserver()

    let _ = await client.addObserver(observer)
    // Successfully added observer
  }

  @Test
  func removeObserver_removesObserver() async {
    let client = await makeTestClient()
    let observer = TestObserver()

    let token = await client.addObserver(observer)
    await client.removeObserver(token)

    // Observer should be removed (no way to verify directly, but ensures no crash)
  }

  // Note: Builder preconditionFailure tests cannot be tested in Swift Testing.
  // These are programmer errors that should be caught during development.

  // MARK: - Helpers

  private func makeTestClient() async -> SpotifyClient<UserAuthCapability> {
    let token = SpotifyTokens(
      accessToken: "TOKEN",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let auth = MockTokenAuthenticator(token: token)
    return SpotifyClient<UserAuthCapability>(
      backend: auth,
      httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
    )
  }
}

// MARK: - Test Helpers

private final class TestObserver: SpotifyClientObserver, @unchecked Sendable {
  func receive(_ event: SpotifyClientEvent) {}
}

private actor FailingTokenAuthenticator: TokenGrantAuthenticator {
  func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
    throw TestError.general("Token refresh failed")
  }

  func loadPersistedTokens() async throws -> SpotifyTokens? {
    return nil
  }
}

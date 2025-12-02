import Foundation
import Testing

@testable import SpotifyKit

@Suite
struct TokenGrantAuthenticatorTests {

  // MARK: - Protocol Conformance Tests

  @Test("SpotifyPKCEAuthenticator conforms to TokenGrantAuthenticator")
  func pkceAuthenticatorConformsToProtocol() async throws {
    let config = AuthTestFixtures.pkceConfig(scopes: [])
    let auth = SpotifyPKCEAuthenticator(
      config: config,
      tokenStore: InMemoryTokenStore(tokens: nil)
    )

    let _: any TokenGrantAuthenticator = auth
  }

  @Test("SpotifyAuthorizationCodeAuthenticator conforms to TokenGrantAuthenticator")
  func authCodeAuthenticatorConformsToProtocol() async throws {
    let config = AuthTestFixtures.authCodeConfig(scopes: [])
    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: config,
      tokenStore: InMemoryTokenStore(tokens: nil)
    )

    let _: any TokenGrantAuthenticator = auth
  }

  @Test("SpotifyClientCredentialsAuthenticator conforms to TokenGrantAuthenticator")
  func clientCredentialsAuthenticatorConformsToProtocol() async throws {
    let config = AuthTestFixtures.clientCredentialsConfig()
    let auth = SpotifyClientCredentialsAuthenticator(
      config: config,
      tokenStore: nil
    )

    let _: any TokenGrantAuthenticator = auth
  }

  // MARK: - Default Implementation Tests

  @Test("PKCE accessToken without parameter calls with invalidatingPrevious false")
  func pkceAccessTokenDefaultParameter() async throws {
    let validToken = SpotifyTokens(
      accessToken: "VALID",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let config = AuthTestFixtures.pkceConfig(scopes: [])
    let auth = SpotifyPKCEAuthenticator(
      config: config,
      tokenStore: InMemoryTokenStore(tokens: validToken)
    )

    let token = try await auth.accessToken()
    #expect(token.accessToken == "VALID")
  }

  @Test("AuthCode accessToken without parameter calls with invalidatingPrevious false")
  func authCodeAccessTokenDefaultParameter() async throws {
    let validToken = SpotifyTokens(
      accessToken: "VALID",
      refreshToken: "REFRESH",
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let config = AuthTestFixtures.authCodeConfig(scopes: [])
    let auth = SpotifyAuthorizationCodeAuthenticator(
      config: config,
      tokenStore: InMemoryTokenStore(tokens: validToken)
    )

    let token = try await auth.accessToken()
    #expect(token.accessToken == "VALID")
  }

  @Test("ClientCredentials accessToken without parameter calls with invalidatingPrevious false")
  func clientCredentialsAccessTokenDefaultParameter() async throws {
    let validToken = SpotifyTokens(
      accessToken: "VALID",
      refreshToken: nil,
      expiresAt: Date().addingTimeInterval(3600),
      scope: nil,
      tokenType: "Bearer"
    )

    let config = AuthTestFixtures.clientCredentialsConfig()
    let auth = SpotifyClientCredentialsAuthenticator(
      config: config,
      tokenStore: InMemoryTokenStore(tokens: validToken)
    )

    let token = try await auth.accessToken()
    #expect(token.accessToken == "VALID")
  }

  // MARK: - Capability Marker Tests

  @Test("UserAuthCapability conforms to UserSpotifyCapability")
  func userAuthCapabilityConforms() {
    let _: any UserSpotifyCapability.Type = UserAuthCapability.self
  }

  @Test("UserAuthCapability conforms to PublicSpotifyCapability")
  func userAuthCapabilityConformsToPublic() {
    let _: any PublicSpotifyCapability.Type = UserAuthCapability.self
  }

  @Test("AppOnlyAuthCapability conforms to PublicSpotifyCapability")
  func appOnlyAuthCapabilityConforms() {
    let _: any PublicSpotifyCapability.Type = AppOnlyAuthCapability.self
  }

  @Test("UserAuthCapability is Sendable")
  func userAuthCapabilityIsSendable() {
    let _: any Sendable.Type = UserAuthCapability.self
  }

  @Test("AppOnlyAuthCapability is Sendable")
  func appOnlyAuthCapabilityIsSendable() {
    let _: any Sendable.Type = AppOnlyAuthCapability.self
  }
}

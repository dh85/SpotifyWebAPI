import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct SpotifyClientTests {
    
    // MARK: - Factory Method Tests
    
    @Test
    func pkce_createsClientWithCorrectConfiguration() async throws {
        let client = UserSpotifyClient.pkce(
            clientID: "test_client",
            redirectURI: URL(string: "test://callback")!,
            scopes: [.playlistReadPrivate, .userReadEmail],
            showDialog: true,
            tokenStore: InMemoryTokenStore(tokens: nil),
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        )
        
        // Verify client was created
        let _: UserSpotifyClient = client
    }
    
    @Test
    func authorizationCode_createsClientWithCorrectConfiguration() async throws {
        let client = UserSpotifyClient.authorizationCode(
            clientID: "test_client",
            clientSecret: "test_secret",
            redirectURI: URL(string: "test://callback")!,
            scopes: [.playlistModifyPublic],
            showDialog: false,
            tokenStore: InMemoryTokenStore(tokens: nil),
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        )
        
        // Verify client was created
        let _: UserSpotifyClient = client
    }
    
    @Test
    func clientCredentials_createsClientWithCorrectConfiguration() async throws {
        let client = AppSpotifyClient.clientCredentials(
            clientID: "test_client",
            clientSecret: "test_secret",
            scopes: [],
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200)),
            tokenStore: nil
        )
        
        // Verify client was created
        let _: AppSpotifyClient = client
    }
    
    @Test
    func clientCredentials_usesDefaultScopes() async throws {
        let client = AppSpotifyClient.clientCredentials(
            clientID: "test_client",
            clientSecret: "test_secret"
        )
        
        // Verify client was created with defaults
        let _: AppSpotifyClient = client
    }

    @Test
    func builder_configuresPKCEFlow() async throws {
        let httpClient = SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        let configuration = SpotifyClientConfiguration(requestTimeout: 45, maxRateLimitRetries: 3)
        let tokenStore = InMemoryTokenStore()

        let client = UserSpotifyClient
            .builder()
            .withPKCE(
                clientID: "builder_client",
                redirectURI: URL(string: "myapp://callback")!,
                scopes: [.userReadEmail],
                showDialog: true
            )
            .withTokenStore(tokenStore)
            .withHTTPClient(httpClient)
            .withConfiguration(configuration)
            .build()

        let storedHTTP = await client.httpClient
        let storedConfiguration = await client.configuration

        #expect((storedHTTP as? SimpleMockHTTPClient) === httpClient)
        #expect(storedConfiguration.requestTimeout == configuration.requestTimeout)
        #expect(storedConfiguration.maxRateLimitRetries == configuration.maxRateLimitRetries)
    }

    @Test
    func builder_configuresClientCredentialsFlow() async throws {
        let httpClient = SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        let configuration = SpotifyClientConfiguration(requestTimeout: 60, maxRateLimitRetries: 0)
        let tokenStore = InMemoryTokenStore()

        let client = AppSpotifyClient
            .builder()
            .withClientCredentials(
                clientID: "builder_app",
                clientSecret: "super_secret",
                scopes: [.playlistReadPrivate]
            )
            .withTokenStore(tokenStore)
            .withHTTPClient(httpClient)
            .withConfiguration(configuration)
            .build()

        let storedHTTP = await client.httpClient
        let storedConfiguration = await client.configuration

        #expect((storedHTTP as? SimpleMockHTTPClient) === httpClient)
        #expect(storedConfiguration.requestTimeout == configuration.requestTimeout)
        #expect(storedConfiguration.maxRateLimitRetries == configuration.maxRateLimitRetries)
    }
    
    // MARK: - accessToken Tests
    
    @Test
    func accessToken_returnsTokenFromBackend() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        )
        
        let token = try await client.accessToken()
        #expect(token == "VALID_TOKEN")
    }
    
    @Test
    func accessToken_passesInvalidatingPreviousFlag() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        )
        
        _ = try await client.accessToken(invalidatingPrevious: true)
        
        let didInvalidate = await auth.didInvalidatePrevious
        #expect(didInvalidate == true)
    }
    
    @Test
    func accessToken_defaultsToNotInvalidating() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: SimpleMockHTTPClient(response: .success(data: Data(), statusCode: 200))
        )
        
        _ = try await client.accessToken()
        
        let didInvalidate = await auth.didInvalidatePrevious
        #expect(didInvalidate == false)
    }
    
    // MARK: - Type Alias Tests
    
    @Test
    func userSpotifyClient_isAliasForUserAuthCapability() {
        let _: UserSpotifyClient.Type = SpotifyClient<UserAuthCapability>.self
    }
    
    @Test
    func appSpotifyClient_isAliasForAppOnlyAuthCapability() {
        let _: AppSpotifyClient.Type = SpotifyClient<AppOnlyAuthCapability>.self
    }
    
    // MARK: - Capability Constraint Tests
    
    @Test
    func pkce_onlyAvailableForUserAuthCapability() {
        // This test verifies that pkce() is only available on UserSpotifyClient
        let client = UserSpotifyClient.pkce(
            clientID: "test",
            redirectURI: URL(string: "test://callback")!,
            scopes: []
        )
        
        let _: SpotifyClient<UserAuthCapability> = client
    }
    
    @Test
    func authorizationCode_onlyAvailableForUserAuthCapability() {
        // This test verifies that authorizationCode() is only available on UserSpotifyClient
        let client = UserSpotifyClient.authorizationCode(
            clientID: "test",
            clientSecret: "secret",
            redirectURI: URL(string: "test://callback")!,
            scopes: []
        )
        
        let _: SpotifyClient<UserAuthCapability> = client
    }
    
    @Test
    func clientCredentials_onlyAvailableForAppOnlyAuthCapability() {
        // This test verifies that clientCredentials() is only available on AppSpotifyClient
        let client = AppSpotifyClient.clientCredentials(
            clientID: "test",
            clientSecret: "secret"
        )
        
        let _: SpotifyClient<AppOnlyAuthCapability> = client
    }
    
    // MARK: - Integration Tests
    
    @Test
    @MainActor
    func pkceClient_canMakeAuthorizedRequests() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let http = MockHTTPClient()
        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )
        
        let profile = try await client.users.me()
        #expect(profile.id == "mockuser")
    }
    
    @Test
    @MainActor
    func authorizationCodeClient_canMakeAuthorizedRequests() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let http = MockHTTPClient()
        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )
        
        let profile = try await client.users.me()
        #expect(profile.id == "mockuser")
    }
    
    @Test
    @MainActor
    func clientCredentialsClient_canMakePublicRequests() async throws {
        let validToken = SpotifyTokens(
            accessToken: "VALID_TOKEN",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(3600),
            scope: nil,
            tokenType: "Bearer"
        )
        
        let http = MockHTTPClient()
        let albumData = try TestDataLoader.load("album_full")
        await http.addMockResponse(
            data: albumData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/albums/test")!
        )
        
        let auth = MockTokenAuthenticator(token: validToken)
        let client = SpotifyClient<AppOnlyAuthCapability>(
            backend: auth,
            httpClient: http
        )
        
        let album = try await client.albums.get("test")
        #expect(album.name == "Global Warming")
    }
}

import Foundation
import Testing

@testable import SpotifyKit

@Suite("Error Response Handling Integration Tests")
struct ErrorResponseIntegrationTests {

  @Test("400 Bad Request error handled correctly")
  func badRequestErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 400,
      errorMessage: "Bad Request",
      affectedEndpoints: ["/v1/me"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      do {
        _ = try await usersService.me()
        Issue.record("Expected 400 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("400") || errorDescription.contains("Bad Request"))
      }
    }
  }

  @Test("401 Unauthorized error handled correctly")
  func unauthorizedErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 401,
      errorMessage: "Unauthorized",
      affectedEndpoints: ["/v1/me"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      do {
        _ = try await usersService.me()
        Issue.record("Expected 401 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("401") || errorDescription.contains("Unauthorized"))
      }
    }
  }

  @Test("403 Forbidden error handled correctly")
  func forbiddenErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 403,
      errorMessage: "Forbidden",
      affectedEndpoints: ["/v1/me/playlists"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let playlistsService = client.playlists

      do {
        _ = try await playlistsService.myPlaylists()
        Issue.record("Expected 403 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("403") || errorDescription.contains("Forbidden"))
      }
    }
  }

  @Test("404 Not Found error handled correctly")
  func notFoundErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 404,
      errorMessage: "Not Found",
      affectedEndpoints: ["/v1/me"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      do {
        _ = try await usersService.me()
        Issue.record("Expected 404 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("404") || errorDescription.contains("Not Found"))
      }
    }
  }

  @Test("500 Internal Server Error handled correctly")
  func internalServerErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 500,
      errorMessage: "Internal Server Error",
      affectedEndpoints: nil,  // All endpoints
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      do {
        _ = try await usersService.me()
        Issue.record("Expected 500 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(
          errorDescription.contains("500") || errorDescription.contains("Internal Server Error"))
      }
    }
  }

  @Test("502 Bad Gateway error handled correctly")
  func badGatewayErrorHandled() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 502,
      errorMessage: "Bad Gateway",
      affectedEndpoints: ["/v1/me"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      do {
        _ = try await usersService.me()
        Issue.record("Expected 502 error")
      } catch {
        let errorDescription = String(describing: error)
        #expect(errorDescription.contains("502") || errorDescription.contains("Bad Gateway"))
      }
    }
  }

  @Test("Error injection with 'once' behavior")
  func errorInjectionOnce() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 500,
      errorMessage: "Temporary Error",
      affectedEndpoints: ["/v1/me"],
      behavior: .once
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // First request should fail
      do {
        _ = try await usersService.me()
        Issue.record("Expected error on first request")
      } catch {
        // Expected
      }

      // Second request should succeed
      let profile = try await usersService.me()
      #expect(profile.id == "testUser")
    }
  }

  @Test("Error injection with 'nthRequest' behavior")
  func errorInjectionNthRequest() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 500,
      errorMessage: "Error on 3rd request",
      affectedEndpoints: ["/v1/me"],
      behavior: .nthRequest(3)
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // First two requests should succeed
      _ = try await usersService.me()
      _ = try await usersService.me()

      // Third request should fail
      do {
        _ = try await usersService.me()
        Issue.record("Expected error on 3rd request")
      } catch {
        // Expected
      }

      // Fourth request should succeed
      let profile = try await usersService.me()
      #expect(profile.id == "testUser")
    }
  }

  @Test("Error injection with 'everyNthRequest' behavior")
  func errorInjectionEveryNthRequest() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 503,
      errorMessage: "Service Unavailable",
      affectedEndpoints: ["/v1/me"],
      behavior: .everyNthRequest(2)  // Every 2nd request fails
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users

      // 1st request: succeeds
      _ = try await usersService.me()

      // 2nd request: fails
      do {
        _ = try await usersService.me()
        Issue.record("Expected error on 2nd request")
      } catch {
        // Expected
      }

      // 3rd request: succeeds
      _ = try await usersService.me()

      // 4th request: fails
      do {
        _ = try await usersService.me()
        Issue.record("Expected error on 4th request")
      } catch {
        // Expected
      }
    }
  }

  @Test("Error injection affects only specified endpoints")
  func errorInjectionAffectsOnlySpecifiedEndpoints() async throws {
    let errorConfig = SpotifyMockAPIServer.ErrorInjectionConfig(
      statusCode: 500,
      errorMessage: "Error",
      affectedEndpoints: ["/v1/me/playlists"],
      behavior: .always
    )

    let config = SpotifyMockAPIServer.Configuration(
      errorInjection: errorConfig
    )
    let server = SpotifyMockAPIServer(configuration: config)

    try await server.withRunningServer { info in
      let client = makeUserClient(for: info)
      let usersService = client.users
      let playlistsService = client.playlists

      // /v1/me should work
      let profile = try await usersService.me()
      #expect(profile.id == "testUser")

      // /v1/me/playlists should fail
      do {
        _ = try await playlistsService.myPlaylists()
        Issue.record("Expected error on playlists endpoint")
      } catch {
        // Expected
      }
    }
  }

  // MARK: - Helper Methods

  private func makeUserClient(for info: SpotifyMockAPIServer.RunningServer)
    -> SpotifyClient<UserAuthCapability>
  {
    let authenticator = SpotifyClientCredentialsAuthenticator(
      config: .clientCredentials(
        clientID: "integration-client",
        clientSecret: "integration-secret",
        scopes: [.userReadEmail, .playlistReadPrivate, .playlistModifyPrivate],
        tokenEndpoint: info.tokenEndpoint
      ),
      httpClient: URLSessionHTTPClient()
    )

    return SpotifyClient<UserAuthCapability>(
      backend: authenticator,
      httpClient: URLSessionHTTPClient(),
      configuration: SpotifyClientConfiguration(
        networkRecovery: .disabled,
        requestDeduplicationEnabled: false,
        apiBaseURL: info.apiBaseURL
      )
    )
  }
}

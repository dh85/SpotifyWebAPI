import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Network Recovery Tests")
@MainActor
struct NetworkRecoveryTests {

  @Test("Network recovery retries on timeout")
  func networkRecoveryRetriesOnTimeout() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 2,
        baseRetryDelay: 0.1
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    // First two requests timeout, third succeeds
    await http.addMockResponse(statusCode: 0)  // Will cause URLError.timedOut
    await http.addMockResponse(statusCode: 0)
    await http.addMockResponse(
      data: try TestDataLoader.load("album_full"),
      statusCode: 200
    )

    let album = try await client.albums.get("test")
    #expect(album.id == "4aawyAB9vmqN3uQ7FjRGTy")

    let requests = await http.requests
    #expect(requests.count == 3)  // Original + 2 retries
  }

  @Test("Network recovery retries on 503 service unavailable")
  func networkRecoveryRetriesOn503() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 1,
        baseRetryDelay: 0.1
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    // First request fails with 503, second succeeds
    await http.addMockResponse(statusCode: 503)
    await http.addMockResponse(
      data: try TestDataLoader.load("album_full"),
      statusCode: 200
    )

    let album = try await client.albums.get("test")
    #expect(album.id == "4aawyAB9vmqN3uQ7FjRGTy")

    let requests = await http.requests
    #expect(requests.count == 2)
  }

  @Test("Network recovery does not retry on 404")
  func networkRecoveryDoesNotRetryOn404() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 2,
        baseRetryDelay: 0.1
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    await http.addMockResponse(statusCode: 404)

    do {
      _ = try await client.albums.get("nonexistent")
      Issue.record("Expected error but request succeeded")
    } catch {
      // Should fail immediately without retries
    }

    let requests = await http.requests
    #expect(requests.count == 1)  // No retries for 404
  }

  @Test("Network recovery respects max retry limit")
  func networkRecoveryRespectsMaxRetries() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 2,
        baseRetryDelay: 0.1
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    // All requests fail with 503
    for _ in 0...3 {
      await http.addMockResponse(statusCode: 503)
    }

    do {
      _ = try await client.albums.get("test")
      Issue.record("Expected error but request succeeded")
    } catch {
      // Should eventually fail after max retries
    }

    let requests = await http.requests
    #expect(requests.count == 3)  // Original + 2 retries, then stop
  }

  @Test("Network recovery uses exponential backoff")
  func networkRecoveryUsesExponentialBackoff() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 2,
        baseRetryDelay: 0.1,
        maxRetryDelay: 1.0
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    // All requests fail
    for _ in 0...3 {
      await http.addMockResponse(statusCode: 503)
    }

    let startTime = Date()

    do {
      _ = try await client.albums.get("test")
    } catch {
      // Expected to fail
    }

    let duration = Date().timeIntervalSince(startTime)

    // Should take at least 0.1 + 0.2 = 0.3 seconds due to exponential backoff
    #expect(duration >= 0.3)
    #expect(duration < 2.0)  // But not too long
  }

  @Test("Network recovery can be disabled")
  func networkRecoveryCanBeDisabled() async throws {
    let config = SpotifyClientConfiguration(
      networkRecovery: .disabled
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    await http.addMockResponse(statusCode: 503)

    do {
      _ = try await client.albums.get("test")
      Issue.record("Expected error but request succeeded")
    } catch {
      // Should fail immediately
    }

    let requests = await http.requests
    #expect(requests.count == 1)  // No retries when disabled
  }

  @Test("Network recovery configuration error descriptions")
  func networkRecoveryConfigurationErrorDescriptions() {
    let descriptionCases: [(NetworkRecoveryConfigurationError, String)] = [
      (
        .negativeRetryCount(-1),
        "maxNetworkRetries must be >= 0 (received -1)"
      ),
      (
        .nonPositiveBaseDelay(0),
        "baseRetryDelay must be > 0 (received 0.0)"
      ),
      (
        .invalidMaxDelay(base: 2, max: 1),
        "maxRetryDelay (1.0) must be >= baseRetryDelay (2.0)"
      ),
    ]

    for (error, expected) in descriptionCases {
      #expect(error.description == expected)
    }
  }

  @Test("Network recovery configuration validation")
  func networkRecoveryConfigurationValidation() {
    let config = NetworkRecoveryConfiguration(
      maxNetworkRetries: 5,
      baseRetryDelay: 0.5,
      maxRetryDelay: 10.0
    )

    #expect(config.maxNetworkRetries == 5)
    #expect(config.baseRetryDelay == 0.5)
    #expect(config.maxRetryDelay == 10.0)
    #expect(config.retryableNetworkErrors.contains(.timedOut))
    #expect(config.retryableStatusCodes.contains(503))
  }

  @Test("Network recovery validate rejects negative retry count")
  func networkRecoveryValidateRejectsNegativeRetries() {
    let config = NetworkRecoveryConfiguration(maxNetworkRetries: -1)

    expectValidationError(config) { error in
      guard case .negativeRetryCount(let value) = error else {
        Issue.record("Expected negativeRetryCount, received \(error)")
        return
      }
      #expect(value == -1)
    }
  }

  @Test("Network recovery validate rejects invalid max delay")
  func networkRecoveryValidateRejectsInvalidMaxDelay() {
    let config = NetworkRecoveryConfiguration(
      baseRetryDelay: 2,
      maxRetryDelay: 1
    )

    expectValidationError(config) { error in
      guard case .invalidMaxDelay(let base, let max) = error else {
        Issue.record("Expected invalidMaxDelay, received \(error)")
        return
      }
      #expect(base == 2)
      #expect(max == 1)
    }
  }

  @Test("Network recovery preserves rate limit handling")
  func networkRecoveryPreservesRateLimitHandling() async throws {
    let config = SpotifyClientConfiguration(
      maxRateLimitRetries: 1,
      networkRecovery: NetworkRecoveryConfiguration(
        maxNetworkRetries: 1,
        baseRetryDelay: 0.1
      )
    )
    let (client, http) = makeUserAuthClient(configuration: config)

    // First request gets rate limited, second succeeds
    await http.addMockResponse(statusCode: 429, headers: ["Retry-After": "1"])
    await http.addMockResponse(
      data: try TestDataLoader.load("album_full"),
      statusCode: 200
    )

    let album = try await client.albums.get("test")
    #expect(album.id == "4aawyAB9vmqN3uQ7FjRGTy")

    let requests = await http.requests
    #expect(requests.count == 2)  // Rate limit retry should still work
  }

  @Test("Network recovery retries SpotifyAuthError HTTP responses")
  func networkRecoveryRetriesSpotifyAuthErrors() async throws {
    let handler = NetworkRecoveryHandler(
      configuration: NetworkRecoveryConfiguration(
        maxNetworkRetries: 1,
        baseRetryDelay: 0.001,
        maxRetryDelay: 0.001,
        retryableStatusCodes: [503]
      )
    )

    actor AttemptCounter {
      private var value = 0
      func increment() -> Int {
        value += 1
        return value
      }

      func current() -> Int { value }
    }
    let counter = AttemptCounter()
    let value: Int = try await handler.executeWithRecovery {
      let attempt = await counter.increment()
      if attempt == 1 {
        throw SpotifyAuthError.httpError(statusCode: 503, body: "retry")
      }
      return 123
    }

    #expect(value == 123)
    #expect(await counter.current() == 2)
  }
}

private func expectValidationError(
  _ config: NetworkRecoveryConfiguration,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column,
  verifier: (NetworkRecoveryConfigurationError) -> Void
) {
  do {
    try config.validate()
    Issue.record(
      "Expected validation to fail",
      sourceLocation: makeSourceLocation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    )
  } catch let error as NetworkRecoveryConfigurationError {
    verifier(error)
  } catch {
    Issue.record(
      "Unexpected error: \(error)",
      sourceLocation: makeSourceLocation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
    )
  }
}

// MARK: - Mock HTTP Client Extension

extension MockHTTPClient {
  func addMockResponse(statusCode: Int, headers: [String: String] = [:]) async {
    if statusCode == 0 {
      addNetworkError(.timedOut)
    } else {
      addMockResponse(
        data: Data(),
        statusCode: statusCode,
        url: URL(string: "https://api.spotify.com")!,
        headers: headers
      )
    }
  }
}

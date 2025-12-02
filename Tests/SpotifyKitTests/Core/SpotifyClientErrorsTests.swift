import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyClientErrorsTests {

  @Test
  func unexpectedResponseIsNotRetryable() {
    let error = SpotifyClientError.unexpectedResponse
    #expect(!error.isRetryable)
    #expect(error.retryStrategy == .doNotRetry)
  }

  @Test
  func invalidRequestIsNotRetryable() {
    let error = SpotifyClientError.invalidRequest(reason: "Too many IDs")
    #expect(!error.isRetryable)
    #expect(error.retryStrategy == .doNotRetry)
  }

  @Test
  func networkFailureIsRetryable() {
    let error = SpotifyClientError.networkFailure("Connection timeout")
    #expect(error.isRetryable)
    #expect(error.retryStrategy == .exponentialBackoff(maxRetries: 3, baseDelay: 1.0))
  }

  @Test
  func httpError429IsRetryable() {
    let error = SpotifyClientError.httpError(statusCode: 429, body: "Rate limited")
    #expect(error.isRetryable)
    #expect(error.retryStrategy == .rateLimitBackoff)
  }

  @Test
  func httpError500IsRetryable() {
    let error = SpotifyClientError.httpError(statusCode: 500, body: "Server error")
    #expect(error.isRetryable)
    #expect(error.retryStrategy == .exponentialBackoff(maxRetries: 3, baseDelay: 2.0))
  }

  @Test
  func httpError400IsNotRetryable() {
    let error = SpotifyClientError.httpError(statusCode: 400, body: "Bad request")
    #expect(!error.isRetryable)
    #expect(error.retryStrategy == .doNotRetry)
  }

  @Test
  func offlineIsNotRetryable() {
    let error = SpotifyClientError.offline
    #expect(!error.isRetryable)
    #expect(error.retryStrategy == .doNotRetry)
  }

  @Test
  func unexpectedResponseDescription() {
    let error = SpotifyClientError.unexpectedResponse
    #expect(error.errorDescription.contains("unexpected"))
  }

  @Test
  func invalidRequestDescriptionWithParameter() {
    let error = SpotifyClientError.invalidRequest(
      reason: "Too many IDs",
      parameter: "ids",
      validRange: "1-50"
    )
    let desc = error.errorDescription
    #expect(desc.contains("Too many IDs"))
    #expect(desc.contains("ids"))
    #expect(desc.contains("1-50"))
  }

  @Test
  func invalidRequestDescriptionWithoutParameter() {
    let error = SpotifyClientError.invalidRequest(reason: "Invalid format")
    let desc = error.errorDescription
    #expect(desc.contains("Invalid format"))
  }

  @Test
  func networkFailureDescription() {
    let error = SpotifyClientError.networkFailure("Timeout")
    let desc = error.errorDescription
    #expect(desc.contains("Timeout"))
    #expect(desc.contains("internet connection"))
  }

  @Test
  func httpError400Description() {
    let error = SpotifyClientError.httpError(statusCode: 400, body: "Invalid ID")
    let desc = error.errorDescription
    #expect(desc.contains("Bad Request"))
    #expect(desc.contains("Invalid ID"))
  }

  @Test
  func httpError401Description() {
    let error = SpotifyClientError.httpError(statusCode: 401, body: "")
    let desc = error.errorDescription
    #expect(desc.contains("Unauthorized"))
    #expect(desc.contains("Authentication"))
  }

  @Test
  func httpError403Description() {
    let error = SpotifyClientError.httpError(statusCode: 403, body: "")
    let desc = error.errorDescription
    #expect(desc.contains("Forbidden"))
    #expect(desc.contains("permission"))
  }

  @Test
  func httpError404Description() {
    let error = SpotifyClientError.httpError(statusCode: 404, body: "")
    let desc = error.errorDescription
    #expect(desc.contains("Not Found"))
  }

  @Test
  func httpError429Description() {
    let error = SpotifyClientError.httpError(statusCode: 429, body: "")
    let desc = error.errorDescription
    #expect(desc.contains("Rate Limited"))
  }

  @Test
  func httpError500Description() {
    let error = SpotifyClientError.httpError(statusCode: 500, body: "")
    let desc = error.errorDescription
    #expect(desc.contains("Server Error"))
  }

  @Test
  func httpErrorWithEmptyBody() {
    let error = SpotifyClientError.httpError(statusCode: 404, body: "")
    let desc = error.errorDescription
    #expect(!desc.contains("Details:"))
  }

  @Test
  func offlineDescription() {
    let error = SpotifyClientError.offline
    let desc = error.errorDescription
    #expect(desc.contains("offline"))
    #expect(desc.contains("disabled"))
  }

  @Test
  func retryStrategyDoNotRetryDescription() {
    let strategy = RetryStrategy.doNotRetry
    #expect(strategy.description.contains("not be retried"))
  }

  @Test
  func retryStrategyExponentialBackoffDescription() {
    let strategy = RetryStrategy.exponentialBackoff(maxRetries: 3, baseDelay: 1.5)
    let desc = strategy.description
    #expect(desc.contains("3"))
    #expect(desc.contains("1.5"))
  }

  @Test
  func retryStrategyRateLimitBackoffDescription() {
    let strategy = RetryStrategy.rateLimitBackoff
    let desc = strategy.description
    #expect(desc.contains("rate limit"))
    #expect(desc.contains("Retry-After"))
  }

  @Test
  func errorsAreEquatable() {
    let error1 = SpotifyClientError.offline
    let error2 = SpotifyClientError.offline
    #expect(error1 == error2)

    let error3 = SpotifyClientError.unexpectedResponse
    #expect(error1 != error3)
  }

  @Test
  func retryStrategiesAreEquatable() {
    let strategy1 = RetryStrategy.doNotRetry
    let strategy2 = RetryStrategy.doNotRetry
    #expect(strategy1 == strategy2)

    let strategy3 = RetryStrategy.rateLimitBackoff
    #expect(strategy1 != strategy3)
  }
}

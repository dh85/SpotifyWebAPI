import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite("Rate Limit Info Tests")
struct RateLimitInfoTests {

  @Test
  func parseRateLimitHeaders() {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [
        "X-RateLimit-Remaining": "50",
        "X-RateLimit-Reset": "1732464000",
        "X-RateLimit-Limit": "100",
      ]
    )!

    let info = RateLimitInfo.parse(from: response, path: "/v1/me")

    #expect(info != nil)
    #expect(info?.remaining == 50)
    #expect(info?.limit == 100)
    #expect(info?.resetDate != nil)
    #expect(info?.statusCode == 200)
    #expect(info?.path == "/v1/me")
  }

  @Test
  func parsePartialHeaders() {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [
        "X-RateLimit-Remaining": "25"
      ]
    )!

    let info = RateLimitInfo.parse(from: response, path: "/v1/me")

    #expect(info != nil)
    #expect(info?.remaining == 25)
    #expect(info?.limit == nil)
    #expect(info?.resetDate == nil)
  }

  @Test
  func parseNoRateLimitHeaders() {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [:]
    )!

    let info = RateLimitInfo.parse(from: response, path: "/v1/me")

    #expect(info == nil)
  }

  @Test
  func parseInvalidHeaders() {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [
        "X-RateLimit-Remaining": "not-a-number",
        "X-RateLimit-Reset": "invalid",
        "X-RateLimit-Limit": "also-invalid",
      ]
    )!

    let info = RateLimitInfo.parse(from: response, path: "/v1/me")

    // Should return nil since all values are invalid
    #expect(info == nil)
  }

  @Test
  func rateLimitInfoEquality() {
    let date = Date(timeIntervalSince1970: 1_732_464_000)

    let info1 = RateLimitInfo(
      remaining: 50,
      resetDate: date,
      limit: 100,
      statusCode: 200,
      path: "/v1/me"
    )

    let info2 = RateLimitInfo(
      remaining: 50,
      resetDate: date,
      limit: 100,
      statusCode: 200,
      path: "/v1/me"
    )

    let info3 = RateLimitInfo(
      remaining: 25,
      resetDate: date,
      limit: 100,
      statusCode: 200,
      path: "/v1/me"
    )

    #expect(info1 == info2)
    #expect(info1 != info3)
  }

  @Test
  @MainActor
  func clientCallbackReceivesRateLimitInfo() async throws {
    let (client, http) = makeUserAuthClient()

    let infoActor = RateLimitInfoHolder()
    await client.events.onRateLimitInfo { info in
      Task { await infoActor.set(info) }
    }

    let albumData = try TestDataLoader.load("album_full")

    await http.addMockResponse(
      data: albumData,
      statusCode: 200,
      headers: [
        "X-RateLimit-Remaining": "75",
        "X-RateLimit-Limit": "100",
        "X-RateLimit-Reset": "1732464000",
      ]
    )

    _ = try await client.albums.get("test-album-id")

    // Give callback time to execute
    try await Task.sleep(for: .milliseconds(100))

    let receivedInfo = await infoActor.get()
    #expect(receivedInfo != nil)
    #expect(receivedInfo?.remaining == 75)
    #expect(receivedInfo?.limit == 100)
    #expect(receivedInfo?.statusCode == 200)
  }

  @Test
  @MainActor
  func instrumentationReceivesRateLimitEvents() async throws {
    let (client, http) = makeUserAuthClient()
    let collector = InstrumentationEventCollector()
    let token = await client.addObserver(InstrumentationObserver(collector: collector))
    defer { Task { await client.removeObserver(token) } }

    let albumData = try TestDataLoader.load("album_full")

    await http.addMockResponse(
      data: albumData,
      statusCode: 200,
      headers: [
        "X-RateLimit-Remaining": "42",
        "X-RateLimit-Limit": "100",
        "X-RateLimit-Reset": "1732464000",
      ]
    )

    _ = try await client.albums.get("instrumented-album")

    let rateLimit = await collector.waitForEvent(timeout: .milliseconds(500)) {
      event -> RateLimitInfo? in
      guard case .rateLimit(let info) = event else { return nil }
      guard info.path.contains("instrumented-album") else { return nil }
      return info
    }

    guard let first = rateLimit else {
      Issue.record("Expected rate limit instrumentation event")
      return
    }

    #expect(first.remaining == 42)
    #expect(first.limit == 100)
    #expect(first.statusCode == 200)
  }

  @Test
  @MainActor
  func callbackNotCalledWhenNoRateLimitHeaders() async throws {
    let (client, http) = makeUserAuthClient()

    let invokedActor = BoolHolder()
    await client.events.onRateLimitInfo { _ in
      Task { await invokedActor.set(true) }
    }

    let albumData = try TestDataLoader.load("album_full")
    await http.addMockResponse(data: albumData, statusCode: 200)

    _ = try await client.albums.get("test-album-id")

    // Give callback time to execute if it were to be called
    try await Task.sleep(for: .milliseconds(100))

    let callbackInvoked = await invokedActor.get()
    #expect(callbackInvoked == false)
  }
}

// Helper actors for thread-safe state in tests
private actor RateLimitInfoHolder {
  private var info: RateLimitInfo?

  func set(_ newInfo: RateLimitInfo) {
    info = newInfo
  }

  func get() -> RateLimitInfo? {
    info
  }
}

private actor BoolHolder {
  private var value = false

  func set(_ newValue: Bool) {
    value = newValue
  }

  func get() -> Bool {
    value
  }
}

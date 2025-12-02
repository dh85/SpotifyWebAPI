import Foundation
import Testing

@testable import SpotifyKit

// MARK: - Test Client Factories

func extractIDs(from url: URL?) -> Set<String> {
  guard
    let query = url?.query,
    let idsPart =
      query
      .split(separator: "&")
      .first(where: { $0.hasPrefix("ids=") })
  else { return [] }

  let raw = idsPart.dropFirst("ids=".count)
  return Set(raw.split(separator: ",").map(String.init))
}

/// Helper to create a user-auth client with mocks.
@MainActor
func makeUserAuthClient(
  configuration: SpotifyClientConfiguration = .default
) -> (
  client: SpotifyClient<UserAuthCapability>,
  http: MockHTTPClient
) {
  let http = MockHTTPClient()
  let auth = MockTokenAuthenticator(token: .mockValid)
  let client = SpotifyClient<UserAuthCapability>(
    backend: auth,
    httpClient: http,
    configuration: configuration
  )
  return (client, http)
}

/// Helper to create a user auth client with access to the auth object for testing.
func makeUserAuthClientWithAuth(
  initialToken: SpotifyTokens = .mockValid,
  configuration: SpotifyClientConfiguration = .default
) -> (
  client: SpotifyClient<UserAuthCapability>,
  http: MockHTTPClient,
  auth: MockTokenAuthenticator
) {
  let http = MockHTTPClient()
  let auth = MockTokenAuthenticator(token: initialToken)
  let client = SpotifyClient<UserAuthCapability>(
    backend: auth,
    httpClient: http,
    configuration: configuration
  )
  return (client, http, auth)
}

/// Helper to create a predictable set of IDs like "id_1", "id_2", ...
func makeIDs(prefix: String = "id_", count: Int) -> Set<String> {
  Set((1...count).map { "\(prefix)\($0)" })
}

/// Generates an array of test IDs with a given prefix.
func makeTestIDs(_ prefix: String, count: Int) -> [String] {
  (1...count).map { "\(prefix)\($0)" }
}

/// Creates a network recovery configuration for testing.
func makeRecoveryConfig(
  maxRetries: Int = 2,
  baseDelay: TimeInterval = 0.1
) -> SpotifyClientConfiguration {
  SpotifyClientConfiguration(
    networkRecovery: NetworkRecoveryConfiguration(
      maxNetworkRetries: maxRetries,
      baseRetryDelay: baseDelay
    )
  )
}

// MARK: - Paginated Response Builders

/// Builds mock `Page` JSON using items from an existing fixture.
func makePaginatedPage<Item: Codable & Sendable & Equatable>(
  fixture: String,
  of type: Item.Type,
  offset: Int,
  limit: Int = 50,
  total: Int,
  hasNext: Bool,
  extractor: ((String) throws -> Page<Item>)? = nil
) throws -> Page<Item> {
  let base: Page<Item>
  if let extractor {
    base = try extractor(fixture)
  } else {
    let data = try TestDataLoader.load(fixture)
    base = try decodeModel(from: data)
  }
  return Page<Item>(
    href: base.href,
    items: base.items,
    limit: limit,
    next: hasNext ? base.href : nil,
    offset: offset,
    previous: nil,
    total: total
  )
}

func makePaginatedResponse<Item: Codable & Sendable & Equatable>(
  fixture: String,
  of type: Item.Type,
  offset: Int,
  limit: Int = 50,
  total: Int,
  hasNext: Bool,
  extractor: ((String) throws -> Page<Item>)? = nil
) throws -> Data {
  let page: Page<Item> = try makePaginatedPage(
    fixture: fixture,
    of: type,
    offset: offset,
    limit: limit,
    total: total,
    hasNext: hasNext,
    extractor: extractor
  )
  return try encodeModel(page)
}

@discardableResult
func enqueueTwoPageResponses<Item: Codable & Sendable & Equatable>(
  fixture: String,
  of type: Item.Type,
  firstOffset: Int = 0,
  secondOffset: Int = 50,
  limit: Int = 50,
  total: Int = 3,
  http: MockHTTPClient,
  wrap: ((Page<Item>) throws -> Data)? = nil,
  extractor: ((String) throws -> Page<Item>)? = nil
) async throws -> (first: Data, second: Data) {
  let firstPage = try makePaginatedPage(
    fixture: fixture,
    of: Item.self,
    offset: firstOffset,
    limit: limit,
    total: total,
    hasNext: true,
    extractor: extractor
  )
  let secondPage = try makePaginatedPage(
    fixture: fixture,
    of: Item.self,
    offset: secondOffset,
    limit: limit,
    total: total,
    hasNext: false,
    extractor: extractor
  )
  let firstData = try wrap?(firstPage) ?? encodeModel(firstPage)
  let secondData = try wrap?(secondPage) ?? encodeModel(secondPage)
  await http.addMockResponse(data: firstData, statusCode: 200)
  await http.addMockResponse(data: secondData, statusCode: 200)
  return (firstData, secondData)
}

/// Builds an in-memory page for ad-hoc tests without hitting fixtures.
func makeStubPage<T>(
  baseURL: URL = URL(string: "https://api.spotify.com/v1/test")!,
  limit: Int,
  offset: Int,
  total: Int = 10_000,
  items: @autoclosure () -> [T]
) -> Page<T> where T: Sendable {
  let nextOffset = offset + limit
  let nextURL =
    nextOffset < total
    ? URL(string: "\(baseURL.absoluteString)?offset=\(nextOffset)")!
    : nil
  let previousURL =
    offset == 0
    ? nil
    : URL(
      string: "\(baseURL.absoluteString)?offset=\(max(offset - limit, 0))")!

  return Page(
    href: baseURL,
    items: items(),
    limit: limit,
    next: nextURL,
    offset: offset,
    previous: previousURL,
    total: total
  )
}

/// Generates multiple paginated response pages for testing pagination.
///
/// - Parameters:
///   - fixture: The JSON fixture file to use for items
///   - type: The item type to decode
///   - pageSize: Number of items per page
///   - pageCount: Number of pages to generate
///   - totalItems: Total number of items across all pages
/// - Returns: Array of encoded page data
func makeMultiplePaginatedPages<Item: Codable & Sendable & Equatable>(
  fixture: String,
  of type: Item.Type,
  pageSize: Int,
  pageCount: Int,
  totalItems: Int
) throws -> [Data] {
  var pages: [Data] = []
  for pageIndex in 0..<pageCount {
    let offset = pageIndex * pageSize
    let hasNext = (pageIndex + 1) < pageCount
    let page = try makePaginatedResponse(
      fixture: fixture,
      of: type,
      offset: offset,
      limit: pageSize,
      total: totalItems,
      hasNext: hasNext
    )
    pages.append(page)
  }
  return pages
}

// MARK: - Stream Collection Helpers

/// Collects all items from an async stream.
///
/// Reduces boilerplate for stream collection tests.
func collectStreamItems<T>(
  _ stream: AsyncThrowingStream<T, any Error>
) async throws -> [T] {
  var items: [T] = []
  for try await item in stream {
    items.append(item)
  }
  return items
}

func collectPageOffsets<Item>(
  _ stream: AsyncThrowingStream<Page<Item>, Error>
) async throws -> [Int] {
  var offsets: [Int] = []
  for try await page in stream {
    offsets.append(page.offset)
  }
  return offsets
}

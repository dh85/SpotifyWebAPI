import Foundation
import Testing

@testable import SpotifyKit

@Suite
@MainActor
struct FluentRequestTests {

  @Test
  func queryWithDictionaryAddsMultipleParameters() async throws {
    let (client, http) = makeUserAuthClient()
    let data = try TestDataLoader.load("current_user_profile")
    await http.addMockResponse(data: data, statusCode: 200)

    _ = try await client
      .get("/v1/test")
      .query(["limit": 10, "offset": 5, "market": "US"])
      .decode(CurrentUserProfile.self)

    let request = await http.firstRequest
    let url = request?.url?.absoluteString ?? ""
    #expect(url.contains("limit=10"))
    #expect(url.contains("offset=5"))
    #expect(url.contains("market=US"))
  }

  @Test
  func queryWithDictionarySkipsNilValues() async throws {
    let (client, http) = makeUserAuthClient()
    let data = try TestDataLoader.load("current_user_profile")
    await http.addMockResponse(data: data, statusCode: 200)

    _ = try await client
      .get("/v1/test")
      .query(["present": "yes", "missing": nil as String?])
      .decode(CurrentUserProfile.self)

    let request = await http.firstRequest
    let url = request?.url?.absoluteString ?? ""
    #expect(url.contains("present=yes"))
    #expect(!url.contains("missing"))
  }

  @Test
  func queryWithDictionaryHandlesEmptyDictionary() async throws {
    let (client, http) = makeUserAuthClient()
    let data = try TestDataLoader.load("current_user_profile")
    await http.addMockResponse(data: data, statusCode: 200)

    _ = try await client
      .get("/v1/test")
      .query([:])
      .decode(CurrentUserProfile.self)

    let request = await http.firstRequest
    #expect(request?.url?.query == nil || request?.url?.query == "")
  }
}

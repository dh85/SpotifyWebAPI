import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyRequestTests {

  @Test
  func init_setsAllProperties() {
    let query = [URLQueryItem(name: "limit", value: "10")]
    let body = ["key": "value"]

    let request: SpotifyRequest<String> = SpotifyRequest(
      method: .post,
      path: "/test",
      query: query,
      body: body
    )

    #expect(request.method == .post)
    #expect(request.path == "/test")
    #expect(request.query.count == 1)
    #expect(request.query[0].name == "limit")
    #expect(request.requiresAuth == true)
  }

  @Test
  func get_createsGetRequest() {
    let request: SpotifyRequest<String> = .get("/albums/123")

    #expect(request.method == .get)
    #expect(request.path == "/albums/123")
    #expect(request.query.isEmpty)
    #expect(request.body == nil)
    #expect(request.requiresAuth == true)
  }

  @Test
  func get_withQuery_includesQueryItems() {
    let query = [URLQueryItem(name: "market", value: "US")]
    let request: SpotifyRequest<String> = .get("/albums/123", query: query)

    #expect(request.method == .get)
    #expect(request.query.count == 1)
    #expect(request.query[0].name == "market")
  }

  @Test
  func put_createsPutRequest() {
    let request: SpotifyRequest<String> = .put("/playlists/123")

    #expect(request.method == .put)
    #expect(request.path == "/playlists/123")
    #expect(request.body == nil)
  }

  @Test
  func put_withBody_includesBody() {
    let body = ["name": "New Playlist"]
    let request: SpotifyRequest<String> = .put("/playlists/123", body: body)

    #expect(request.method == .put)
    #expect(request.body != nil)
  }

  @Test
  func post_createsPostRequest() {
    let request: SpotifyRequest<String> = .post("/playlists")

    #expect(request.method == .post)
    #expect(request.path == "/playlists")
    #expect(request.body == nil)
  }

  @Test
  func post_withBodyAndQuery_includesBoth() {
    let query = [URLQueryItem(name: "position", value: "0")]
    let body = ["uris": ["spotify:track:123"]]
    let request: SpotifyRequest<String> = .post("/playlists/123/tracks", query: query, body: body)

    #expect(request.method == .post)
    #expect(request.query.count == 1)
    #expect(request.body != nil)
  }

  @Test
  func delete_createsDeleteRequest() {
    let request: SpotifyRequest<String> = .delete("/playlists/123/tracks")

    #expect(request.method == .delete)
    #expect(request.path == "/playlists/123/tracks")
    #expect(request.body == nil)
  }

  @Test
  func delete_withBody_includesBody() {
    let body = ["tracks": [["uri": "spotify:track:123"]]]
    let request: SpotifyRequest<String> = .delete("/playlists/123/tracks", body: body)

    #expect(request.method == .delete)
    #expect(request.body != nil)
  }

  @Test
  func requiresAuth_alwaysTrue() {
    let getRequest: SpotifyRequest<String> = .get("/test")
    let postRequest: SpotifyRequest<String> = .post("/test")
    let putRequest: SpotifyRequest<String> = .put("/test")
    let deleteRequest: SpotifyRequest<String> = .delete("/test")

    #expect(getRequest.requiresAuth == true)
    #expect(postRequest.requiresAuth == true)
    #expect(putRequest.requiresAuth == true)
    #expect(deleteRequest.requiresAuth == true)
  }
}

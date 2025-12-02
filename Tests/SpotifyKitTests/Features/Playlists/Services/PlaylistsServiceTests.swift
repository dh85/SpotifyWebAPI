import Foundation
import Testing

@testable import SpotifyKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@Suite
@MainActor
struct PlaylistsServiceTests {

  // MARK: - Public Access Tests

  @Test
  func getBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlist_full.json") { client, http in
      let id = "playlist123"
      let playlist = try await client.playlists.get(
        id, market: "US", fields: "name,id", additionalTypes: [.track, .episode])

      #expect(playlist.id == id)
      expectRequest(
        await http.firstRequest, path: "/v1/playlists/\(id)", method: "GET",
        queryContains: "market=US", "fields=name,id", "additional_types=episode,track")
    }
  }

  @Test(arguments: [nil, "US"])
  func getIncludesMarketParameter(market: String?) async throws {
    try await withMockServiceClient(fixture: "playlist_full.json") { client, http in
      _ = try await client.playlists.get("playlist123", market: market)

      expectMarketParameter(await http.firstRequest, market: market)
    }
  }

  @Test
  func itemsBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http in
      let page = try await client.playlists.items(
        "playlist123", market: "US", fields: "items", limit: 10, offset: 5,
        additionalTypes: [.episode])

      #expect(page.items.count > 0)
      expectRequest(
        await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "GET",
        queryContains: "limit=10", "offset=5", "market=US", "fields=items",
        "additional_types=episode")
    }
  }

  @Test
  func itemsUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "playlist_tracks.json") { client in
      _ = try await client.playlists.items("playlist123")
    }
  }

  @Test
  func itemsThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.playlists.items("id", limit: limit)
    }
  }

  @Test
  func streamItemPagesFetchesAllPages() async throws {
    let (client, http) = makeUserAuthClient()
    let first = try makePaginatedResponse(
      fixture: "playlist_tracks.json",
      of: PlaylistTrackItem.self,
      offset: 0,
      total: 3,
      hasNext: true
    )
    let second = try makePaginatedResponse(
      fixture: "playlist_tracks.json",
      of: PlaylistTrackItem.self,
      offset: 50,
      total: 3,
      hasNext: false
    )
    await http.addMockResponse(data: first, statusCode: 200)
    await http.addMockResponse(data: second, statusCode: 200)

    let stream = client.playlists.streamItemPages("playlist123")
    let pages = try await collectStreamItems(stream)

    #expect(pages.count == 2)
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "GET")
  }

  @Test
  func userPlaylistsBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlists_user.json") { client, http in
      let page = try await client.playlists.userPlaylists(
        userID: "user123", limit: 10, offset: 5)

      #expect(page.items.count > 0)
      expectRequest(
        await http.firstRequest, path: "/v1/users/user123/playlists", method: "GET",
        queryContains: "limit=10", "offset=5")
    }
  }

  @Test
  func userPlaylistsUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "playlists_user.json") { client in
      _ = try await client.playlists.userPlaylists(userID: "user123")
    }
  }

  @Test
  func userPlaylistsThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.playlists.userPlaylists(userID: "user123", limit: limit)
    }
  }

  @Test
  func coverImageBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlist_images.json") { client, http in
      let images = try await client.playlists.coverImage(id: "playlist123")

      #expect(images.count > 0)
      expectRequest(
        await http.firstRequest, path: "/v1/playlists/playlist123/images", method: "GET")
    }
  }

  // MARK: - User Access Tests

  @Test
  func myPlaylistsBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlists_user.json") { client, http in
      let page = try await client.playlists.myPlaylists(limit: 10, offset: 5)

      #expect(page.items.count > 0)
      expectRequest(
        await http.firstRequest, path: "/v1/me/playlists", method: "GET",
        queryContains: "limit=10", "offset=5")
    }
  }

  @Test
  func myPlaylistsUsesDefaultPagination() async throws {
    try await expectDefaultPagination(fixture: "playlists_user.json") { client in
      _ = try await client.playlists.myPlaylists()
    }
  }

  @Test
  func myPlaylistsThrowsErrorWhenLimitOutOfBounds() async throws {
    let (client, _) = makeUserAuthClient()
    await expectLimitErrors { limit in
      _ = try await client.playlists.myPlaylists(limit: limit)
    }
  }

  @Test
  func streamMyPlaylistPagesFetchesAllPages() async throws {
    let (client, http) = makeUserAuthClient()
    let first = try makePaginatedResponse(
      fixture: "playlists_user.json",
      of: SimplifiedPlaylist.self,
      offset: 0,
      total: 3,
      hasNext: true
    )
    let second = try makePaginatedResponse(
      fixture: "playlists_user.json",
      of: SimplifiedPlaylist.self,
      offset: 50,
      total: 3,
      hasNext: false
    )
    await http.addMockResponse(data: first, statusCode: 200)
    await http.addMockResponse(data: second, statusCode: 200)

    let stream = client.playlists.streamMyPlaylistPages()
    let pages = try await collectStreamItems(stream)
    let totalItems = pages.reduce(0) { $0 + $1.items.count }

    #expect(totalItems > 0)
    expectRequest(await http.firstRequest, path: "/v1/me/playlists", method: "GET")
  }

  @Test
  func createBuildsCorrectRequest() async throws {
    try await withMockServiceClient(fixture: "playlist_full.json", statusCode: 201) {
      client, http in
      let playlist = try await client.playlists.create(
        for: "user123", name: "My Playlist", isPublic: true)

      #expect(playlist.name == "Test Playlist")
      expectRequest(
        await http.firstRequest, path: "/v1/users/user123/playlists", method: "POST")
    }
  }

  @Test
  func changeDetailsBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await client.playlists.changeDetails(
      id: "playlist123", name: "New Name", isPublic: false)

    expectRequest(await http.firstRequest, path: "/v1/playlists/playlist123", method: "PUT")
  }

  @Test
  func changeDetailsWithoutArgumentsDoesNothing() async throws {
    let (client, http) = makeUserAuthClient()

    try await client.playlists.changeDetails(id: "playlist123")

    let request = await http.firstRequest
    #expect(request == nil)
  }

  @Test(
    "Change playlist details",
    arguments: [
      ("Updated Name" as String?, nil as Bool?, nil as Bool?, nil as String?),
      (nil, false, nil, nil),
      (nil, nil, true, nil),
      (nil, nil, nil, "Updated description"),
    ])
  func changeDetailsSendsRequestForEachField(scenario: (String?, Bool?, Bool?, String?))
    async throws
  {

    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await client.playlists.changeDetails(
      id: "playlist123",
      name: scenario.0,
      isPublic: scenario.1,
      collaborative: scenario.2,
      description: scenario.3
    )

    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123", method: "PUT")
  }

  @Test
  func addBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    let snapshotData = """
      {"snapshot_id": "snap123"}
      """.data(using: .utf8)!
    await http.addMockResponse(data: snapshotData, statusCode: 201)

    let snapshotId = try await client.playlists.add(
      to: "playlist123", uris: ["spotify:track:track1", "spotify:track:track2"])

    #expect(snapshotId == "snap123")
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "POST")
  }

  @Test
  func removeBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    let snapshotData = """
      {"snapshot_id": "snap456"}
      """.data(using: .utf8)!
    await http.addMockResponse(data: snapshotData, statusCode: 200)

    let snapshotId = try await client.playlists.remove(
      from: "playlist123", uris: ["spotify:track:track1"])

    #expect(snapshotId == "snap456")
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "DELETE")
  }

  @Test
  func reorderBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    let snapshotData = """
      {"snapshot_id": "snap789"}
      """.data(using: .utf8)!
    await http.addMockResponse(data: snapshotData, statusCode: 200)

    let snapshotId = try await client.playlists.reorder(
      id: "playlist123", rangeStart: 0, insertBefore: 5, rangeLength: 2)

    #expect(snapshotId == "snap789")
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "PUT")
  }

  @Test
  func replaceBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 201)

    try await client.playlists.replace(
      itemsIn: "playlist123", with: ["spotify:track:track1", "spotify:track:track2"])

    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "PUT",
      queryContains: "uris=")
  }

  @Test
  func followBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await client.playlists.follow("playlist123", isPublic: true)

    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/followers", method: "PUT")
  }

  @Test
  func unfollowBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 200)

    try await client.playlists.unfollow("playlist123")

    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/followers", method: "DELETE")
  }

  @Test
  func uploadCoverImageBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 202)

    let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    try await client.playlists.uploadCoverImage(for: "playlist123", jpegData: jpegData)

    let request = await http.firstRequest
    #expect(request?.url?.path() == "/v1/playlists/playlist123/images")
    #expect(request?.httpMethod == "PUT")
    #expect(request?.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
  }

  @Test
  func uploadCoverImageThrowsErrorOnFailure() async throws {
    let (client, http) = makeUserAuthClient()
    await http.addMockResponse(statusCode: 400)

    let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])

    do {
      try await client.playlists.uploadCoverImage(for: "playlist123", jpegData: jpegData)
      Issue.record("Expected error to be thrown")
    } catch let error as SpotifyAuthError {
      if case .httpError(let statusCode, _) = error {
        #expect(statusCode == 400)
      } else {
        Issue.record("Expected httpError, got \(error)")
      }
    }
  }

  @Test
  func removeByPositionsBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    let snapshotData = """
      {"snapshot_id": "snap999"}
      """.data(using: .utf8)!
    await http.addMockResponse(data: snapshotData, statusCode: 200)

    let snapshotId = try await client.playlists.remove(
      from: "playlist123", positions: [0, 2, 5], snapshotId: "snap123")

    #expect(snapshotId == "snap999")
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "DELETE")
  }

  @Test
  func addWithPositionBuildsCorrectRequest() async throws {
    let (client, http) = makeUserAuthClient()
    let snapshotData = """
      {"snapshot_id": "snap555"}
      """.data(using: .utf8)!
    await http.addMockResponse(data: snapshotData, statusCode: 201)

    let snapshotId = try await client.playlists.add(
      to: "playlist123", uris: ["spotify:track:track1"], position: 5)

    #expect(snapshotId == "snap555")
    expectRequest(
      await http.firstRequest, path: "/v1/playlists/playlist123/tracks", method: "POST")
  }

  @Test
  func addThrowsErrorWhenURILimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    let uris = (1...101).map { "spotify:track:track\($0)" }

    await expectInvalidRequest(reasonContains: "Maximum of 100") {
      _ = try await client.playlists.add(to: "playlist123", uris: uris)
    }
  }

  @Test
  func removeByURIsThrowsErrorWhenURILimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    let uris = (1...101).map { "spotify:track:track\($0)" }

    await expectInvalidRequest(reasonContains: "Maximum of 100") {
      _ = try await client.playlists.remove(from: "playlist123", uris: uris)
    }
  }

  @Test
  func removeByPositionsThrowsErrorWhenPositionLimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    let positions = Array(0...100)

    await expectInvalidRequest(reasonContains: "Maximum of 100") {
      _ = try await client.playlists.remove(from: "playlist123", positions: positions)
    }
  }

  @Test
  func replaceThrowsErrorWhenURILimitExceeded() async throws {
    let (client, _) = makeUserAuthClient()
    let uris = (1...101).map { "spotify:track:track\($0)" }

    await expectInvalidRequest(reasonContains: "Maximum of 100") {
      try await client.playlists.replace(itemsIn: "playlist123", with: uris)
    }
  }

  // MARK: - Convenience Method Tests

  @Test
  func allMyPlaylistsFetchesAllPages() async throws {
    let (client, http) = makeUserAuthClient()

    // Page 1: 2 playlists, has next
    let page1 = makePage(
      items: ["playlist1", "playlist2"],
      limit: 2,
      offset: 0,
      total: 5,
      hasNext: true
    )
    // Page 2: 2 playlists, has next
    let page2 = makePage(
      items: ["playlist3", "playlist4"],
      limit: 2,
      offset: 2,
      total: 5,
      hasNext: true
    )
    // Page 3: 1 playlist, no next
    let page3 = makePage(
      items: ["playlist5"],
      limit: 2,
      offset: 4,
      total: 5,
      hasNext: false
    )

    await http.addMockResponse(data: page1, statusCode: 200)
    await http.addMockResponse(data: page2, statusCode: 200)
    await http.addMockResponse(data: page3, statusCode: 200)

    let allPlaylists = try await client.playlists.allMyPlaylists()

    #expect(allPlaylists.count == 5)
    #expect(
      allPlaylists.map(\.id) == [
        "playlist1", "playlist2", "playlist3", "playlist4", "playlist5",
      ])
  }

  @Test
  func allMyPlaylistsRespectsMaxItems() async throws {
    let (client, http) = makeUserAuthClient()

    let page1 = makePage(
      items: ["playlist1", "playlist2"],
      limit: 2,
      offset: 0,
      total: 10,
      hasNext: true
    )
    let page2 = makePage(
      items: ["playlist3", "playlist4"],
      limit: 2,
      offset: 2,
      total: 10,
      hasNext: true
    )

    await http.addMockResponse(data: page1, statusCode: 200)
    await http.addMockResponse(data: page2, statusCode: 200)

    let playlists = try await client.playlists.allMyPlaylists(maxItems: 3)

    #expect(playlists.count == 3)
    #expect(playlists.map(\.id) == ["playlist1", "playlist2", "playlist3"])
  }

  @Test
  func allMyPlaylistsHandlesEmptyResult() async throws {
    let (client, http) = makeUserAuthClient()

    let emptyPage = makePage(
      items: [] as [String],
      limit: 50,
      offset: 0,
      total: 0,
      hasNext: false
    )

    await http.addMockResponse(data: emptyPage, statusCode: 200)

    let playlists = try await client.playlists.allMyPlaylists()

    #expect(playlists.isEmpty)
  }

  @Test
  func allMyPlaylistsUsesDefaultMaxItems() async throws {
    try await withMockServiceClient(fixture: "playlists_user.json") { client, http, data in
      guard let playlistsData = data else {
        Issue.record("Missing playlists fixture data")
        return
      }
      // Mock enough responses to exceed default limit
      for _ in 1..<25 {  // Already enqueued once.
        await http.addMockResponse(data: playlistsData, statusCode: 200)
      }

      let playlists = try await client.playlists.allMyPlaylists()

      // Should stop at default limit of 1000, not fetch all
      #expect(playlists.count <= 1000)
    }
  }

  @Test
  func allMyPlaylistsAllowsUnlimitedWithNil() async throws {
    let (client, http) = makeUserAuthClient()

    let page = makePage(
      items: ["p1", "p2"],
      limit: 2,
      offset: 0,
      total: 2,
      hasNext: false
    )

    await http.addMockResponse(data: page, statusCode: 200)

    let playlists = try await client.playlists.allMyPlaylists(maxItems: nil)

    #expect(playlists.count == 2)
  }

  @Test
  func allItemsFetchesAllPages() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      // Mock 3 pages of results (one already enqueued)
      await http.addMockResponse(data: itemsData, statusCode: 200)
      await http.addMockResponse(data: itemsData, statusCode: 200)

      let allItems = try await client.playlists.allItems("playlist123")

      #expect(allItems.count > 0)
    }
  }

  @Test
  func allItemsRespectsMaxItems() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      await http.addMockResponse(data: itemsData, statusCode: 200)

      let items = try await client.playlists.allItems("playlist123", maxItems: 1)

      #expect(items.count == 1)
    }
  }

  @Test
  func allItemsPassesParametersCorrectly() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, _ in
      _ = try await client.playlists.allItems(
        "playlist123",
        market: "US",
        fields: "items(track(name))",
        additionalTypes: [.episode]
      )

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: ["market=US", "fields=items(track(name))", "additional_types=episode"])
    }
  }

  @Test
  func allItemsUsesDefaultMaxItems() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      // Mock enough responses to exceed default limit (one already added)
      for _ in 1..<150 {
        await http.addMockResponse(data: itemsData, statusCode: 200)
      }

      let items = try await client.playlists.allItems("playlist123")

      // Should stop at default limit of 5000, not fetch all
      #expect(items.count <= 5000)
    }
  }

  @Test
  func allItemsAllowsUnlimitedWithNil() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, _, _ in
      let items = try await client.playlists.allItems("playlist123", maxItems: nil)

      #expect(items.count > 0)
    }
  }

  @Test
  func streamItemsYieldsAllItems() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      // Mock 2 pages (one already queued)
      await http.addMockResponse(data: itemsData, statusCode: 200)

      let stream = client.playlists.streamItems("playlist123")
      let items = try await collectStreamItems(stream)

      #expect(items.count > 0)
    }
  }

  @Test
  func streamItemsRespectsMaxItems() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      await http.addMockResponse(data: itemsData, statusCode: 200)

      let stream = client.playlists.streamItems("playlist123", maxItems: 1)
      let items = try await collectStreamItems(stream)

      // Should stop at maxItems
      #expect(items.count == 1)
    }
  }

  @Test
  func streamItemsPassesParameters() async throws {
    try await withMockServiceClient(fixture: "playlist_tracks.json") { client, http, data in
      guard let itemsData = data else {
        Issue.record("Missing playlist tracks fixture")
        return
      }

      await http.addMockResponse(data: itemsData, statusCode: 200)

      let stream = client.playlists.streamItems(
        "playlist123",
        market: "US",
        fields: "items(track(name))",
        additionalTypes: [.episode]
      )
      let itemCount = try await collectStreamItems(stream).count

      let request = await http.firstRequest
      expectQueryParameters(
        request,
        contains: ["market=US", "fields=items(track(name))", "additional_types=episode"])
      #expect(itemCount > 0)
    }
  }

  // MARK: - Helper Methods

  private func makePage(
    items: [String],
    limit: Int,
    offset: Int,
    total: Int,
    hasNext: Bool
  ) -> Data {
    let itemsJSON = items.map { id in
      """
      {
          "collaborative": false,
          "description": "Test playlist",
          "external_urls": {"spotify": "https://open.spotify.com/playlist/\(id)"},
          "href": "https://api.spotify.com/v1/playlists/\(id)",
          "id": "\(id)",
          "images": [],
          "name": "Playlist \(id)",
          "owner": {
              "id": "user123",
              "display_name": "Test User",
              "href": "https://api.spotify.com/v1/users/user123",
              "type": "user",
              "uri": "spotify:user:user123",
              "external_urls": {"spotify": "https://open.spotify.com/user/user123"}
          },
          "public": true,
          "snapshot_id": "snapshot",
          "tracks": {"href": "https://api.spotify.com/v1/playlists/\(id)/tracks", "total": 10},
          "type": "playlist",
          "uri": "spotify:playlist:\(id)"
      }
      """
    }.joined(separator: ",")

    let nextURL =
      hasNext
      ? "\"https://api.spotify.com/v1/me/playlists?offset=\(offset + limit)&limit=\(limit)\""
      : "null"

    let json = """
      {
          "href": "https://api.spotify.com/v1/me/playlists?offset=\(offset)&limit=\(limit)",
          "items": [\(itemsJSON)],
          "limit": \(limit),
          "next": \(nextURL),
          "offset": \(offset),
          "previous": null,
          "total": \(total)
      }
      """

    return json.data(using: .utf8)!
  }
}

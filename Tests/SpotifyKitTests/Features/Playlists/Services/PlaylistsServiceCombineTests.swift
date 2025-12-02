#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Playlists Service Combine Tests")
  @MainActor
  struct PlaylistsServiceCombineTests {

    @Test("getPublisher emits playlist")
    func getPublisherEmitsPlaylist() async throws {
      let playlist = try await assertPublisherRequest(
        fixture: "playlist_full.json",
        path: "/v1/playlists/playlist123",
        method: "GET",
        queryContains: [
          "market=US",
          "fields=name,id",
          "additional_types=episode,track",
        ]
      ) { client in
        let playlists = client.playlists
        return playlists.getPublisher(
          "playlist123",
          market: "US",
          fields: "name,id",
          additionalTypes: [.track, .episode]
        )
      }

      #expect(playlist.id == "playlist123")
    }

    @Test("itemsPublisher builds correct request")
    func itemsPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "playlist_tracks.json",
        path: "/v1/playlists/playlist123/tracks",
        method: "GET",
        queryContains: [
          "limit=10",
          "offset=5",
          "market=US",
          "fields=items",
          "additional_types=episode",
        ]
      ) { client in
        let playlists = client.playlists
        return playlists.itemsPublisher(
          "playlist123",
          market: "US",
          fields: "items",
          limit: 10,
          offset: 5,
          additionalTypes: [.episode]
        )
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("itemsPublisher validates limits")
    func itemsPublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let playlists = client.playlists
      await expectPublisherLimitValidation { limit in
        playlists.itemsPublisher("playlist123", limit: limit)
      }
    }

    @Test("allItemsPublisher aggregates pages")
    func allItemsPublisherAggregatesPages() async throws {
      try await assertAggregatesPages(
        fixture: "playlist_tracks.json",
        of: PlaylistTrackItem.self
      ) { client in
        let playlists = client.playlists
        return playlists.allItemsPublisher("playlist123")
      }
    }

    @Test("userPlaylistsPublisher builds correct request")
    func userPlaylistsPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "playlists_user.json",
        path: "/v1/users/user123/playlists",
        method: "GET",
        queryContains: ["limit=10", "offset=5"]
      ) { client in
        let playlists = client.playlists
        return playlists.userPlaylistsPublisher(userID: "user123", limit: 10, offset: 5)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("coverImagePublisher builds correct request")
    func coverImagePublisherBuildsRequest() async throws {
      let images = try await assertPublisherRequest(
        fixture: "playlist_images.json",
        path: "/v1/playlists/playlist123/images",
        method: "GET"
      ) { client in
        let playlists = client.playlists
        return playlists.coverImagePublisher(id: "playlist123")
      }

      #expect(images.isEmpty == false)
    }

    @Test("myPlaylistsPublisher builds correct request")
    func myPlaylistsPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "playlists_user.json",
        path: "/v1/me/playlists",
        method: "GET",
        queryContains: ["limit=10", "offset=5"]
      ) { client in
        let playlists = client.playlists
        return playlists.myPlaylistsPublisher(limit: 10, offset: 5)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("allMyPlaylistsPublisher aggregates pages")
    func allMyPlaylistsPublisherAggregatesPages() async throws {
      try await assertAggregatesPages(
        fixture: "playlists_user.json",
        of: SimplifiedPlaylist.self
      ) { client in
        let playlists = client.playlists
        return playlists.allMyPlaylistsPublisher()
      }
    }

    @Test("createPublisher builds correct request")
    func createPublisherBuildsRequest() async throws {
      let playlist = try await assertPublisherRequest(
        fixture: "playlist_full.json",
        path: "/v1/users/user123/playlists",
        method: "POST",
        statusCode: 201
      ) { client in
        let playlists = client.playlists
        return playlists.createPublisher(
          for: "user123",
          name: "My Playlist",
          isPublic: true
        )
      }

      #expect(playlist.name == "Test Playlist")
    }

    @Test("changeDetailsPublisher builds correct request")
    func changeDetailsPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 200)
      let playlists = client.playlists

      _ = try await awaitFirstValue(
        playlists.changeDetailsPublisher(
          id: "playlist123", name: "Renamed", isPublic: false)
      )

      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123",
        method: "PUT"
      )
    }

    @Test("addPublisher builds correct request")
    func addPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      let snapshotData = "{\"snapshot_id\":\"snap123\"}".data(using: .utf8)!
      await http.addMockResponse(data: snapshotData, statusCode: 201)
      let playlists = client.playlists
      let ids = ["spotify:track:1", "spotify:track:2"]

      let snapshot = try await awaitFirstValue(
        playlists.addPublisher(to: "playlist123", uris: ids))

      #expect(snapshot == "snap123")
      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/tracks",
        method: "POST"
      )
    }

    @Test("addPublisher validates URI count")
    func addPublisherValidatesURICount() async {
      let (client, _) = makeUserAuthClient()
      let playlists = client.playlists
      let uris = Array(repeating: "spotify:track:1", count: 101)

      do {
        _ = try await awaitFirstValue(playlists.addPublisher(to: "playlist123", uris: uris))
        Issue.record("Expected validation error for >100 URIs")
      } catch let error as SpotifyClientError {
        switch error {
        case .invalidRequest(let reason):
          #expect(reason.contains("Maximum of 100"))
        default:
          Issue.record("Unexpected SpotifyClientError: \(error)")
        }
      } catch {
        Issue.record("Unexpected error: \(error)")
      }
    }

    @Test("removePublisher by URI builds correct request")
    func removePublisherByURIBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      let snapshotData = "{\"snapshot_id\":\"snap456\"}".data(using: .utf8)!
      await http.addMockResponse(data: snapshotData, statusCode: 200)
      let playlists = client.playlists

      let snapshot = try await awaitFirstValue(
        playlists.removePublisher(from: "playlist123", uris: ["spotify:track:1"])
      )

      #expect(snapshot == "snap456")
      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/tracks",
        method: "DELETE"
      )
    }

    @Test("removePublisher by positions builds correct request")
    func removePublisherByPositionsBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      let snapshotData = "{\"snapshot_id\":\"snap789\"}".data(using: .utf8)!
      await http.addMockResponse(data: snapshotData, statusCode: 200)
      let playlists = client.playlists

      let snapshot = try await awaitFirstValue(
        playlists.removePublisher(
          from: "playlist123", positions: [0, 2], snapshotID: "snap123")
      )

      #expect(snapshot == "snap789")
      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/tracks",
        method: "DELETE"
      )
    }

    @Test("reorderPublisher builds correct request")
    func reorderPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      let snapshotData = "{\"snapshot_id\":\"snap999\"}".data(using: .utf8)!
      await http.addMockResponse(data: snapshotData, statusCode: 200)
      let playlists = client.playlists

      let snapshot = try await awaitFirstValue(
        playlists.reorderPublisher(
          in: "playlist123",
          rangeStart: 0,
          insertBefore: 5,
          rangeLength: 2
        )
      )

      #expect(snapshot == "snap999")
      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/tracks",
        method: "PUT"
      )
    }

    @Test("replacePublisher builds correct request")
    func replacePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 201)
      let playlists = client.playlists

      _ = try await awaitFirstValue(
        playlists.replacePublisher(in: "playlist123", with: ["spotify:track:1"])
      )

      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/tracks",
        method: "PUT",
        queryContains: "uris="
      )
    }

    @Test("uploadCoverImagePublisher builds correct request")
    func uploadCoverImagePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 202)
      let playlists = client.playlists

      _ = try await awaitFirstValue(
        playlists.uploadCoverImagePublisher(
          for: "playlist123", jpegData: Data([0xFF, 0xD8]))
      )

      let request = await http.firstRequest
      #expect(request?.url?.path() == "/v1/playlists/playlist123/images")
      #expect(request?.httpMethod == "PUT")
    }

    @Test("followPublisher builds correct request")
    func followPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 200)
      let playlists = client.playlists

      _ = try await awaitFirstValue(playlists.followPublisher("playlist123", isPublic: true))

      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/followers",
        method: "PUT"
      )
    }

    @Test("unfollowPublisher builds correct request")
    func unfollowPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 200)
      let playlists = client.playlists

      _ = try await awaitFirstValue(playlists.unfollowPublisher("playlist123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/playlists/playlist123/followers",
        method: "DELETE"
      )
    }
  }

#endif

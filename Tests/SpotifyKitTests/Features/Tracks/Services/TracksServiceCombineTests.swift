#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Tracks Service Combine Tests")
  @MainActor
  struct TracksServiceCombineTests {

    @Test("getPublisher builds correct request")
    func getPublisherBuildsCorrectRequest() async throws {
      let track = try await assertPublisherRequest(
        fixture: "track_full.json",
        path: "/v1/tracks/track_id",
        method: "GET",
        queryContains: ["market=US"]
      ) { client in
        let tracks = client.tracks
        return tracks.getPublisher("track_id", market: "US")
      }

      #expect(track.id == "track_id")
    }

    @Test("severalPublisher builds correct request")
    func severalPublisherBuildsCorrectRequest() async throws {
      let ids: Set<String> = ["track1", "track2"]
      let result = try await assertPublisherRequest(
        fixture: "tracks_several.json",
        path: "/v1/tracks",
        method: "GET",
        queryContains: ["market=GB"],
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let tracks = client.tracks
        return tracks.severalPublisher(ids: ids, market: "GB")
      }

      #expect(result.count == 2)
    }

    @Test("savedPublisher builds correct request")
    func savedPublisherBuildsCorrectRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "tracks_saved.json",
        path: "/v1/me/tracks",
        method: "GET",
        queryContains: ["limit=10", "offset=5", "market=ES"]
      ) { client in
        let tracks = client.tracks
        return tracks.savedPublisher(limit: 10, offset: 5, market: "ES")
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("savedPublisher validates limits")
    func savedPublisherValidatesLimits() async {
      let (client, _) = makeUserAuthClient()
      let tracks = client.tracks

      await expectPublisherLimitValidation { limit in
        tracks.savedPublisher(limit: limit)
      }
    }

    @Test("allSavedTracksPublisher aggregates pages")
    func allSavedTracksPublisherAggregatesPages() async throws {
      try await assertAggregatesPages(
        fixture: "tracks_saved.json",
        of: SavedTrack.self
      ) { client in
        let tracks = client.tracks
        return tracks.allSavedTracksPublisher(market: "US")
      }
    }

    @Test("savePublisher builds correct request")
    func savePublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 3)
      try await assertIDsMutationPublisher(
        path: "/v1/me/tracks",
        method: "PUT",
        ids: ids
      ) { client, ids in
        let tracks = client.tracks
        return tracks.savePublisher(ids)
      }
    }

    @Test("removePublisher builds correct request")
    func removePublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 3)
      try await assertIDsMutationPublisher(
        path: "/v1/me/tracks",
        method: "DELETE",
        ids: ids
      ) { client, ids in
        let tracks = client.tracks
        return tracks.removePublisher(ids)
      }
    }

    @Test("checkSavedPublisher builds correct request")
    func checkSavedPublisherBuildsCorrectRequest() async throws {
      let ids = makeIDs(count: 50)
      let results = try await assertPublisherRequest(
        fixture: "check_saved_tracks.json",
        path: "/v1/me/tracks/contains",
        method: "GET",
        verifyRequest: { request in
          #expect(extractIDs(from: request?.url) == ids)
        }
      ) { client in
        let tracks = client.tracks
        return tracks.checkSavedPublisher(ids)
      }

      #expect(results.count == 50)
    }
  }

#endif

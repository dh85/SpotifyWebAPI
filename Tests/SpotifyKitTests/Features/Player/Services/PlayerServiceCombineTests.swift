#if canImport(Combine)
  import Combine
  import Foundation
  import Testing

  @testable import SpotifyKit

  #if canImport(FoundationNetworking)
    import FoundationNetworking
  #endif

  @Suite("Player Service Combine Tests")
  @MainActor
  struct PlayerServiceCombineTests {

    @Test("statePublisher emits playback state")
    func statePublisherEmitsPlaybackState() async throws {
      let state = try await assertPublisherRequest(
        fixture: "playback_state.json",
        path: "/v1/me/player",
        method: "GET",
        queryContains: ["market=US", "additional_types=episode"]
      ) { client in
        let player = client.player
        return player.statePublisher(market: "US", additionalTypes: [.episode])
      }

      #expect(state != nil)
    }

    @Test("currentlyPlayingPublisher builds correct request")
    func currentlyPlayingPublisherBuildsRequest() async throws {
      let current = try await assertPublisherRequest(
        fixture: "currently_playing.json",
        path: "/v1/me/player/currently-playing",
        method: "GET",
        queryContains: ["market=GB", "additional_types=episode,track"]
      ) { client in
        let player = client.player
        return player.currentlyPlayingPublisher(
          market: "GB",
          additionalTypes: [.track, .episode]
        )
      }

      #expect(current != nil)
    }

    @Test("devicesPublisher emits devices")
    func devicesPublisherEmitsDevices() async throws {
      let devices = try await assertPublisherRequest(
        fixture: "devices.json",
        path: "/v1/me/player/devices",
        method: "GET"
      ) { client in
        let player = client.player
        return player.devicesPublisher()
      }

      #expect(devices.isEmpty == false)
    }

    @Test("transferPublisher builds correct request")
    func transferPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.transferPublisher(to: "device123", play: true))

      expectRequest(await http.firstRequest, path: "/v1/me/player", method: "PUT")
    }

    @Test("resumePublisher builds correct request")
    func resumePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.resumePublisher(deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/play",
        method: "PUT",
        queryContains: "device_id=device123"
      )
    }

    @Test("playContextPublisher builds correct request")
    func playContextPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(
        player.playPublisher(
          contextURI: "spotify:album:abc123",
          deviceID: "device123",
          offset: .position(5)
        )
      )

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/play",
        method: "PUT",
        queryContains: "device_id=device123"
      )
    }

    @Test("playTracksPublisher builds correct request")
    func playTracksPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(
        player.playPublisher(
          uris: ["spotify:track:track1", "spotify:track:track2"],
          deviceID: "device123"
        )
      )

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/play",
        method: "PUT",
        queryContains: "device_id=device123"
      )
    }

    @Test("pausePublisher builds correct request")
    func pausePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.pausePublisher(deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/pause",
        method: "PUT",
        queryContains: "device_id=device123"
      )
    }

    @Test("skipToNextPublisher builds correct request")
    func skipToNextPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.skipToNextPublisher(deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/next",
        method: "POST",
        queryContains: "device_id=device123"
      )
    }

    @Test("skipToPreviousPublisher builds correct request")
    func skipToPreviousPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.skipToPreviousPublisher(deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/previous",
        method: "POST",
        queryContains: "device_id=device123"
      )
    }

    @Test("seekPublisher builds correct request")
    func seekPublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.seekPublisher(to: 30000, deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/seek",
        method: "PUT",
        queryContains: "position_ms=30000",
        "device_id=device123"
      )
    }

    @Test("seekPublisher validates position")
    func seekPublisherValidatesPosition() async {
      let (client, _) = makeUserAuthClient()
      let player = client.player

      do {
        _ = try await awaitFirstValue(player.seekPublisher(to: -1))
        Issue.record("Expected validation error for negative position")
      } catch let error as SpotifyClientError {
        switch error {
        case .invalidRequest(let reason, _, _):
          #expect(reason.contains(">= 0"))
        default:
          Issue.record("Unexpected SpotifyClientError: \(error)")
        }
      } catch {
        Issue.record("Unexpected error: \(error)")
      }
    }

    @Test("setRepeatModePublisher builds correct request")
    func setRepeatModePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(
        player.setRepeatModePublisher(.track, deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/repeat",
        method: "PUT",
        queryContains: "state=track",
        "device_id=device123"
      )
    }

    @Test("setVolumePublisher builds correct request")
    func setVolumePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.setVolumePublisher(50, deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/volume",
        method: "PUT",
        queryContains: "volume_percent=50",
        "device_id=device123"
      )
    }

    @Test("setVolumePublisher validates range")
    func setVolumePublisherValidatesRange() async {
      let (client, _) = makeUserAuthClient()
      let player = client.player

      for value in [-1, 101] {
        do {
          _ = try await awaitFirstValue(player.setVolumePublisher(value))
          Issue.record("Expected validation error for value=\(value)")
        } catch let error as SpotifyClientError {
          switch error {
          case .invalidRequest(let reason, _, _):
            #expect(reason.contains("Volume must be between"))
          default:
            Issue.record("Unexpected SpotifyClientError: \(error)")
          }
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }
    }

    @Test("setShufflePublisher builds correct request")
    func setShufflePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(player.setShufflePublisher(true, deviceID: "device123"))

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/shuffle",
        method: "PUT",
        queryContains: "state=true",
        "device_id=device123"
      )
    }

    @Test("queuePublisher builds correct request")
    func queuePublisherBuildsRequest() async throws {
      let queue = try await assertPublisherRequest(
        fixture: "queue.json",
        path: "/v1/me/player/queue",
        method: "GET"
      ) { client in
        let player = client.player
        return player.queuePublisher()
      }

      #expect(queue.queue.isEmpty == false)
    }

    @Test("addToQueuePublisher builds correct request")
    func addToQueuePublisherBuildsRequest() async throws {
      let (client, http) = makeUserAuthClient()
      await http.addMockResponse(statusCode: 204)
      let player = client.player

      _ = try await awaitFirstValue(
        player.addToQueuePublisher(uri: "spotify:track:track123", deviceID: "device123")
      )

      expectRequest(
        await http.firstRequest,
        path: "/v1/me/player/queue",
        method: "POST",
        queryContains: "uri=spotify:track:track123",
        "device_id=device123"
      )
    }

    @Test("recentlyPlayedPublisher builds correct request")
    func recentlyPlayedPublisherBuildsRequest() async throws {
      let page = try await assertPublisherRequest(
        fixture: "recently_played.json",
        path: "/v1/me/player/recently-played",
        method: "GET",
        queryContains: ["limit=10"]
      ) { client in
        let player = client.player
        return player.recentlyPlayedPublisher(limit: 10)
      }

      #expect(page.items.isEmpty == false)
    }

    @Test("recentlyPlayedPublisher validates limit")
    func recentlyPlayedPublisherValidatesLimit() async {
      let (client, _) = makeUserAuthClient()
      let player = client.player

      for limit in [0, 51] {
        do {
          _ = try await awaitFirstValue(player.recentlyPlayedPublisher(limit: limit))
          Issue.record("Expected limit validation for limit=\(limit)")
        } catch let error as SpotifyClientError {
          switch error {
          case .invalidRequest(let reason, _, _):
            #expect(reason.contains("Limit must be between"))
          default:
            Issue.record("Unexpected SpotifyClientError: \(error)")
          }
        } catch {
          Issue.record("Unexpected error: \(error)")
        }
      }
    }
  }

#endif

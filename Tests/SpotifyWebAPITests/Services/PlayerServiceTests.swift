import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct PlayerServiceTests {

    // MARK: - Playback State Tests

    @Test
    func stateBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let stateData = try TestDataLoader.load("playback_state.json")
        await http.addMockResponse(data: stateData, statusCode: 200)

        let state = try await client.player.state(market: "US", additionalTypes: [.episode])

        #expect(state != nil)
        expectRequest(
            await http.firstRequest, path: "/v1/me/player", method: "GET",
            queryContains: "market=US", "additional_types=episode")
    }

    @Test
    func stateReturnsNilOn204() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        let state = try await client.player.state()

        #expect(state == nil)
    }

    @Test
    func currentlyPlayingBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let currentData = try TestDataLoader.load("currently_playing.json")
        await http.addMockResponse(data: currentData, statusCode: 200)

        let current = try await client.player.currentlyPlaying(
            market: "US", additionalTypes: [.track, .episode])

        #expect(current != nil)
        expectRequest(
            await http.firstRequest, path: "/v1/me/player/currently-playing", method: "GET",
            queryContains: "market=US", "additional_types=episode,track")
    }

    @Test
    func currentlyPlayingReturnsNilOn204() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        let current = try await client.player.currentlyPlaying()

        #expect(current == nil)
    }

    @Test
    func devicesBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let devicesData = try TestDataLoader.load("devices.json")
        await http.addMockResponse(data: devicesData, statusCode: 200)

        let devices = try await client.player.devices()

        #expect(devices.count > 0)
        expectRequest(await http.firstRequest, path: "/v1/me/player/devices", method: "GET")
    }

    // MARK: - Playback Control Tests

    @Test
    func transferBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.transfer(to: "device123", play: true)

        expectRequest(await http.firstRequest, path: "/v1/me/player", method: "PUT")
    }

    @Test
    func resumeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.resume(deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/play", method: "PUT",
            queryContains: "device_id=device123")
    }

    @Test
    func playContextBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.play(
            contextURI: "spotify:album:abc123", deviceID: "device123",
            offset: .position(5))

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/play", method: "PUT",
            queryContains: "device_id=device123")
    }

    @Test
    func playTracksBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.play(
            uris: ["spotify:track:track1", "spotify:track:track2"], deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/play", method: "PUT",
            queryContains: "device_id=device123")
    }

    @Test
    func pauseBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.pause(deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/pause", method: "PUT",
            queryContains: "device_id=device123")
    }

    @Test
    func skipToNextBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.skipToNext(deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/next", method: "POST",
            queryContains: "device_id=device123")
    }

    @Test
    func skipToPreviousBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.skipToPrevious(deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/previous", method: "POST",
            queryContains: "device_id=device123")
    }

    @Test
    func seekBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.seek(to: 30000, deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/seek", method: "PUT",
            queryContains: "position_ms=30000", "device_id=device123")
    }

    @Test
    func seekThrowsErrorForNegativePosition() async throws {
        let (client, _) = makeUserAuthClient()

        await expectInvalidRequest(reasonEquals: "positionMs must be >= 0") {
            try await client.player.seek(to: -1)
        }
    }

    @Test
    func setRepeatModeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.setRepeatMode(.track, deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/repeat", method: "PUT",
            queryContains: "state=track", "device_id=device123")
    }

    @Test
    func setVolumeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.setVolume(50, deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/volume", method: "PUT",
            queryContains: "volume_percent=50", "device_id=device123")
    }

    @Test
    func setVolumeThrowsErrorForInvalidVolume() async throws {
        let (client, _) = makeUserAuthClient()

        await expectInvalidRequest(reasonEquals: "Volume must be between 0 and 100") {
            try await client.player.setVolume(101)
        }

        await expectInvalidRequest(reasonEquals: "Volume must be between 0 and 100") {
            try await client.player.setVolume(-1)
        }
    }

    @Test
    func setShuffleBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.setShuffle(true, deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/shuffle", method: "PUT",
            queryContains: "state=true", "device_id=device123")
    }

    // MARK: - Queue Tests

    @Test
    func getQueueBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let queueData = try TestDataLoader.load("queue.json")
        await http.addMockResponse(data: queueData, statusCode: 200)

        let queue = try await client.player.getQueue()

        #expect(queue.queue.count > 0)
        expectRequest(await http.firstRequest, path: "/v1/me/player/queue", method: "GET")
    }

    @Test
    func addToQueueBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)

        try await client.player.addToQueue(uri: "spotify:track:track123", deviceID: "device123")

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/queue", method: "POST",
            queryContains: "uri=spotify:track:track123", "device_id=device123")
    }

    // MARK: - Recently Played Tests

    @Test
    func recentlyPlayedBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let historyData = try TestDataLoader.load("recently_played.json")
        await http.addMockResponse(data: historyData, statusCode: 200)

        let page = try await client.player.recentlyPlayed(limit: 10)

        #expect(page.items.count > 0)
        expectRequest(
            await http.firstRequest, path: "/v1/me/player/recently-played", method: "GET",
            queryContains: "limit=10")
    }

    @Test
    func recentlyPlayedWithAfterBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let historyData = try TestDataLoader.load("recently_played.json")
        await http.addMockResponse(data: historyData, statusCode: 200)

        let after = Date(timeIntervalSince1970: 1609459200)
        _ = try await client.player.recentlyPlayed(after: after)

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/recently-played", method: "GET",
            queryContains: "after=1609459200000")
    }

    @Test
    func recentlyPlayedWithBeforeBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let historyData = try TestDataLoader.load("recently_played.json")
        await http.addMockResponse(data: historyData, statusCode: 200)

        let before = Date(timeIntervalSince1970: 1609459200)
        _ = try await client.player.recentlyPlayed(before: before)

        expectRequest(
            await http.firstRequest, path: "/v1/me/player/recently-played", method: "GET",
            queryContains: "before=1609459200000")
    }

    @Test
    func recentlyPlayedThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.player.recentlyPlayed(limit: limit)
        }
    }

    @Test
    func recentlyPlayedThrowsErrorWhenBothAfterAndBeforeSpecified() async throws {
        let (client, _) = makeUserAuthClient()
        let date = Date()

        await expectInvalidRequest(reasonEquals: "Cannot specify both 'after' and 'before'") {
            _ = try await client.player.recentlyPlayed(after: date, before: date)
        }
    }
}

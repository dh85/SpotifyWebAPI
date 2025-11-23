import Foundation
import Testing

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@testable import SpotifyWebAPI

@Suite
struct RequestHelpersTests {

    // MARK: - 429 Rate Limit Tests

    @Test
    @MainActor
    func executeRequest_retries429WithRetryAfterHeader() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            statusCode: 429,
            url: URL(string: "https://api.spotify.com/v1/me")!,
            headers: ["Retry-After": "0"]
        )

        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        let profile = try await client.users.me()
        #expect(profile.id == "mockuser")

        let requestCount = await http.requests.count
        #expect(requestCount == 2)
    }



    @Test
    @MainActor
    func executeRequest_doesNotRetry429Twice() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            statusCode: 429,
            url: URL(string: "https://api.spotify.com/v1/me")!,
            headers: ["Retry-After": "0"]
        )

        await http.addMockResponse(
            statusCode: 429,
            url: URL(string: "https://api.spotify.com/v1/me")!,
            headers: ["Retry-After": "0"]
        )

        do {
            _ = try await client.users.me()
            Issue.record("Expected error but succeeded")
        } catch {
            // Expected to fail with 429 on second attempt
        }

        let requestCount = await http.requests.count
        #expect(requestCount == 2)
    }

    // MARK: - 401 Retry Tests

    @Test
    @MainActor
    func authorizedRequest_retriesOn401WithFreshToken() async throws {
        let http = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockExpired)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )

        await http.addMockResponse(
            statusCode: 401,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        _ = try await client.users.me()

        let didInvalidate = await auth.didInvalidatePrevious
        #expect(didInvalidate == true)

        let requestCount = await http.requests.count
        #expect(requestCount == 2)
    }

    @Test
    @MainActor
    func authorizedRequest_throwsOnNonHTTPResponse() async throws {
        let http = NonHTTPResponseMockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await client.users.me()
        }
    }

    // MARK: - perform Tests

    @Test
    @MainActor
    func perform_handles204NoContentForEmptyResponse() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            statusCode: 204,
            url: URL(string: "https://api.spotify.com/v1/me/player/pause")!
        )

        try await client.player.pause()

        let requestCount = await http.requests.count
        #expect(requestCount == 1)
    }

    @Test
    @MainActor
    func perform_throwsOn204ForNonEmptyResponse() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            statusCode: 204,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        await #expect(throws: SpotifyAuthError.unexpectedResponse) {
            _ = try await client.users.me()
        }
    }

    @Test
    @MainActor
    func perform_handles200WithEmptyDataForEmptyResponse() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            data: Data(),
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me/player/pause")!
        )

        try await client.player.pause()

        let requestCount = await http.requests.count
        #expect(requestCount == 1)
    }

    @Test
    @MainActor
    func perform_throwsOnNon2xxStatusCode() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            data: "Bad Request".data(using: .utf8)!,
            statusCode: 400,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        await #expect(throws: SpotifyAuthError.httpError(statusCode: 400, body: "Bad Request")) {
            _ = try await client.users.me()
        }
    }

    @Test
    @MainActor
    func perform_decodesJSONSuccessfully() async throws {
        let (client, http) = makeUserAuthClient()

        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me")!
        )

        let profile = try await client.users.me()
        #expect(profile.id == "mockuser")
        #expect(profile.displayName == "Mock User")
    }


    // MARK: - requestOptionalJSON Tests

    @Test
    @MainActor
    func requestOptionalJSON_returnsNilOn204() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            statusCode: 204,
            url: URL(string: "https://api.spotify.com/v1/me/player")!
        )

        let state = try await client.player.state()
        #expect(state == nil)
    }

    @Test
    @MainActor
    func requestOptionalJSON_returnsNilOn200WithEmptyData() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            data: Data(),
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me/player")!
        )

        let state = try await client.player.state()
        #expect(state == nil)
    }

    @Test
    @MainActor
    func requestOptionalJSON_decodesDataOn200() async throws {
        let (client, http) = makeUserAuthClient()

        let stateData = try TestDataLoader.load("playback_state_track")
        await http.addMockResponse(
            data: stateData,
            statusCode: 200,
            url: URL(string: "https://api.spotify.com/v1/me/player")!
        )

        let state = try await client.player.state()
        #expect(state != nil)
        #expect(state?.isPlaying == true)
    }

    @Test
    @MainActor
    func requestOptionalJSON_throwsOnNon2xxStatusCode() async throws {
        let (client, http) = makeUserAuthClient()

        await http.addMockResponse(
            data: "Forbidden".data(using: .utf8)!,
            statusCode: 403,
            url: URL(string: "https://api.spotify.com/v1/me/player")!
        )

        await #expect(throws: SpotifyAuthError.httpError(statusCode: 403, body: "Forbidden")) {
            _ = try await client.player.state()
        }
    }
}

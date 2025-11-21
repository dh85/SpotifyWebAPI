import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct CoreNetworkingTests {

    let testURL = URL(string: "https://api.spotify.com/v1/me")!

    // MARK: - Factory Helper

    /// Helper to create a user-auth client with mocks
    @MainActor
    private func makeClient(
        initialToken: SpotifyTokens = .mockValid
    ) -> (
        client: SpotifyClient<UserAuthCapability>, http: MockHTTPClient,
        auth: MockTokenAuthenticator
    ) {
        let http = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: initialToken)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )
        return (client, http, auth)
    }

    // MARK: - Tests

    @Test
    @MainActor
    func client_handles401TokenRefresh_andRetriesRequest() async throws {
        // Arrange
        let (client, http, auth) = makeClient(initialToken: .mockExpired)

        // 1. First call: 401 Unauthorized
        await http.addMockResponse(statusCode: 401, url: testURL)

        // 2. Second call: 200 OK with mock data from file
        let profileData = try TestDataLoader.load("current_user_profile.json")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: testURL
        )

        // Act
        // We use client.users.me() which internally calls authorizedRequest
        let profile = try await client.users.me()

        // Assert
        // 1. Check that the profile was successfully decoded
        #expect(profile.id == "mockuser")
        #expect(profile.displayName == "Mock User")

        // 2. Check that the authenticator was asked to invalidate the token
        let didInvalidate = await auth.didInvalidatePrevious
        #expect(
            didInvalidate,
            "The client should have set invalidatingPrevious to true on the 401 retry"
        )

        // 3. Check that the HTTP client was called exactly twice
        let requestCount = await http.requests.count
        #expect(
            requestCount == 2,
            "The client should have made two requests (initial + retry)"
        )

        // 4. (Optional) Check that the first token was the expired one and the second was new
        let requests = await http.requests
        #expect(
            requests[0].value(forHTTPHeaderField: "Authorization")!.contains(
                "EXPIRED_ACCESS_TOKEN"
            )
        )
        #expect(
            requests[1].value(forHTTPHeaderField: "Authorization")!.contains(
                "VALID_ACCESS_TOKEN"
            )
        )
    }

    @Test
    @MainActor
    func client_handles429RateLimit_andRetries() async throws {
        let (client, http, _) = makeClient()

        await http.addMockResponse(
            statusCode: 429,
            url: testURL,
            headers: ["Retry-After": "0"]
        )

        let profileData = try TestDataLoader.load("current_user_profile.json")
        await http.addMockResponse(
            data: profileData,
            statusCode: 200,
            url: testURL
        )

        let profile = try await client.users.me()

        #expect(profile.id == "mockuser")

        let requestCount = await http.requests.count
        #expect(requestCount == 2)
    }
}

import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite
struct CurrentUserProfileTests {

    private func makeProfileJSON() -> Data {
        let json: [String: Any] = [
            "id": "user123",
            "display_name": "Test User",
            "email": "user@example.com",
            "country": "GB",
            "product": "premium",
            "href": "https://api.spotify.com/v1/users/user123",
            "external_urls": [
                "spotify": "https://open.spotify.com/user/user123"
            ],
            "images": [
                [
                    "url": "https://example.com/image.jpg",
                    "height": 300,
                    "width": 300,
                ]
            ],
            "followers": [
                "href": NSNull(),
                "total": 99,
            ],
            "explicit_content": [
                "filter_enabled": true,
                "filter_locked": false,
            ],
        ]

        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private func makeClient() -> (UserSpotifyClient, SequencedMockHTTPClient) {
        let data = makeProfileJSON()
        let httpClient = SequencedMockHTTPClient(
            responses: [
                .init(data: data, statusCode: 200)
            ]
        )

        let tokenStore = InMemoryTokenStore(
            tokens: SpotifyTokens(
                accessToken: "ACCESS",
                refreshToken: "REFRESH",
                expiresAt: Date().addingTimeInterval(3600),
                scope: nil,
                tokenType: "Bearer"
            )
        )
        let client = UserSpotifyClient.authorizationCode(
            clientID: "TEST_CLIENT",
            clientSecret: "TEST_SECRET",
            redirectURI: URL(string: "app://callback")!,
            scopes: [.userReadEmail],
            tokenStore: tokenStore,
            httpClient: httpClient
        )

        return (client, httpClient)
    }

    @Test
    func currentUserProfile_decodesAndHitsCorrectURL() async throws {
        let (client, http) = makeClient()

        let profile = try await client.users.me()

        #expect(profile.id == "user123")
        #expect(profile.displayName == "Test User")
        #expect(profile.email == "user@example.com")
        #expect(profile.country == "GB")
        #expect(profile.product == "premium")

        #expect(profile.images.count == 1)
        #expect(profile.images.first?.height == 300)
        #expect(profile.images.first?.width == 300)

        #expect(profile.followers?.total == 99)
        #expect(profile.explicitContent?.filterEnabled == true)
        #expect(profile.explicitContent?.filterLocked == false)

        #expect(http.requests.count == 1)
        let request = http.requests[0]
        #expect(request.url?.path == "/v1/me")
    }
}

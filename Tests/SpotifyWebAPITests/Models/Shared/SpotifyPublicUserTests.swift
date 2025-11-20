import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyPublicUserTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "external_urls": {
                    "spotify": "https://open.spotify.com/user/user123"
                },
                "href": "https://api.spotify.com/v1/users/user123",
                "id": "user123",
                "type": "user",
                "uri": "spotify:user:user123",
                "display_name": "Test User"
            }
            """
        let data = json.data(using: .utf8)!
        let user: SpotifyPublicUser = try decodeModel(from: data)

        #expect(
            user.externalUrls?.spotify?.absoluteString == "https://open.spotify.com/user/user123")
        #expect(user.href?.absoluteString == "https://api.spotify.com/v1/users/user123")
        #expect(user.id == "user123")
        #expect(user.type == .user)
        #expect(user.uri == "spotify:user:user123")
        #expect(user.displayName == "Test User")
    }

    @Test
    func decodesWithMinimalFields() throws {
        let json = """
            {
                "id": "user456",
                "type": "user",
                "uri": "spotify:user:user456"
            }
            """
        let data = json.data(using: .utf8)!
        let user: SpotifyPublicUser = try decodeModel(from: data)

        #expect(user.externalUrls == nil)
        #expect(user.href == nil)
        #expect(user.id == "user456")
        #expect(user.type == .user)
        #expect(user.uri == "spotify:user:user456")
        #expect(user.displayName == nil)
    }

    @Test
    func decodesWithNullDisplayName() throws {
        let json = """
            {
                "id": "user789",
                "type": "user",
                "uri": "spotify:user:user789",
                "display_name": null
            }
            """
        let data = json.data(using: .utf8)!
        let user: SpotifyPublicUser = try decodeModel(from: data)

        #expect(user.id == "user789")
        #expect(user.displayName == nil)
    }

    @Test
    func encodesCorrectly() throws {
        let user = SpotifyPublicUser(
            externalUrls: SpotifyExternalUrls(
                spotify: URL(string: "https://open.spotify.com/user/test")),
            href: URL(string: "https://api.spotify.com/v1/users/test"),
            id: "test",
            type: .user,
            uri: "spotify:user:test",
            displayName: "Test"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        let decoded: SpotifyPublicUser = try JSONDecoder().decode(
            SpotifyPublicUser.self, from: data)

        #expect(decoded == user)
    }

    @Test
    func equatableWorksCorrectly() {
        let user1 = SpotifyPublicUser(
            externalUrls: nil, href: nil, id: "user1", type: .user,
            uri: "spotify:user:user1", displayName: "User 1")
        let user2 = SpotifyPublicUser(
            externalUrls: nil, href: nil, id: "user1", type: .user,
            uri: "spotify:user:user1", displayName: "User 1")
        let user3 = SpotifyPublicUser(
            externalUrls: nil, href: nil, id: "user2", type: .user,
            uri: "spotify:user:user2", displayName: "User 1")

        #expect(user1 == user2)
        #expect(user1 != user3)
    }
}

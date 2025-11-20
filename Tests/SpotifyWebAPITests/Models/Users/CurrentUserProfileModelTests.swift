import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct CurrentUserProfileModelTests {

    @Test
    func decodesWithAllFields() throws {
        let json = """
            {
                "id": "user123",
                "display_name": "Test User",
                "email": "user@example.com",
                "country": "US",
                "product": "premium",
                "href": "https://api.spotify.com/v1/users/user123",
                "external_urls": {
                    "spotify": "https://open.spotify.com/user/user123"
                },
                "images": [
                    {
                        "url": "https://i.scdn.co/image/test",
                        "height": 300,
                        "width": 300
                    }
                ],
                "followers": {
                    "href": null,
                    "total": 100
                },
                "explicit_content": {
                    "filter_enabled": true,
                    "filter_locked": false
                },
                "type": "user",
                "uri": "spotify:user:user123"
            }
            """
        let data = json.data(using: .utf8)!
        let profile: CurrentUserProfile = try decodeModel(from: data)

        #expect(profile.id == "user123")
        #expect(profile.displayName == "Test User")
        #expect(profile.email == "user@example.com")
        #expect(profile.country == "US")
        #expect(profile.product == "premium")
        #expect(profile.href.absoluteString == "https://api.spotify.com/v1/users/user123")
        #expect(profile.images.count == 1)
        #expect(profile.followers.total == 100)
        #expect(profile.explicitContent?.filterEnabled == true)
        #expect(profile.explicitContent?.filterLocked == false)
        #expect(profile.type == .user)
        #expect(profile.uri == "spotify:user:user123")
    }

    @Test
    func decodesWithoutDisplayName() throws {
        let json = """
            {
                "id": "user789",
                "display_name": null,
                "country": "CA",
                "product": "premium",
                "href": "https://api.spotify.com/v1/users/user789",
                "external_urls": {},
                "images": [],
                "followers": {
                    "href": null,
                    "total": 0
                },
                "explicit_content": {
                    "filter_enabled": false,
                    "filter_locked": false
                },
                "type": "user",
                "uri": "spotify:user:user789"
            }
            """
        let data = json.data(using: .utf8)!
        let profile: CurrentUserProfile = try decodeModel(from: data)

        #expect(profile.id == "user789")
        #expect(profile.displayName == nil)
        #expect(profile.country == "CA")
    }

    @Test
    func decodesWithoutExplicitContent() throws {
        let json = """
            {
                "id": "user999",
                "display_name": "User Without Private Scope",
                "href": "https://api.spotify.com/v1/users/user999",
                "external_urls": {},
                "images": [],
                "followers": {
                    "href": null,
                    "total": 50
                },
                "type": "user",
                "uri": "spotify:user:user999"
            }
            """
        let data = json.data(using: .utf8)!
        let profile: CurrentUserProfile = try decodeModel(from: data)

        #expect(profile.id == "user999")
        #expect(profile.explicitContent == nil)
        #expect(profile.product == nil)
        #expect(profile.country == nil)
    }

    @Test
    func decodesWithoutEmail() throws {
        let json = """
            {
                "id": "user456",
                "display_name": "User Without Email",
                "country": "GB",
                "product": "free",
                "href": "https://api.spotify.com/v1/users/user456",
                "external_urls": {},
                "images": [],
                "followers": {
                    "href": null,
                    "total": 0
                },
                "explicit_content": {
                    "filter_enabled": false,
                    "filter_locked": true
                },
                "type": "user",
                "uri": "spotify:user:user456"
            }
            """
        let data = json.data(using: .utf8)!
        let profile: CurrentUserProfile = try decodeModel(from: data)

        #expect(profile.id == "user456")
        #expect(profile.email == nil)
        #expect(profile.product == "free")
        #expect(profile.explicitContent?.filterLocked == true)
    }

    @Test
    func equatableWorksCorrectly() {
        let profile1 = CurrentUserProfile(
            id: "user1",
            displayName: "User 1",
            email: "user1@example.com",
            country: "US",
            product: "premium",
            href: URL(string: "https://api.spotify.com/v1/users/user1")!,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 10),
            explicitContent: CurrentUserProfile.ExplicitContentSettings(
                filterEnabled: true, filterLocked: false),
            type: .user,
            uri: "spotify:user:user1"
        )
        let profile2 = CurrentUserProfile(
            id: "user1",
            displayName: "User 1",
            email: "user1@example.com",
            country: "US",
            product: "premium",
            href: URL(string: "https://api.spotify.com/v1/users/user1")!,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 10),
            explicitContent: CurrentUserProfile.ExplicitContentSettings(
                filterEnabled: true, filterLocked: false),
            type: .user,
            uri: "spotify:user:user1"
        )
        let profile3 = CurrentUserProfile(
            id: "user2",
            displayName: "User 2",
            email: nil,
            country: "GB",
            product: "free",
            href: URL(string: "https://api.spotify.com/v1/users/user2")!,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 5),
            explicitContent: nil,
            type: .user,
            uri: "spotify:user:user2"
        )

        #expect(profile1 == profile2)
        #expect(profile1 != profile3)
    }

    @Test
    func explicitContentSettingsEquatable() {
        let settings1 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: true, filterLocked: false)
        let settings2 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: true, filterLocked: false)
        let settings3 = CurrentUserProfile.ExplicitContentSettings(
            filterEnabled: false, filterLocked: true)

        #expect(settings1 == settings2)
        #expect(settings1 != settings3)
    }
}

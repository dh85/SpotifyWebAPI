import Foundation
import Testing
@testable import SpotifyWebAPI

@Suite("PublicUserProfile Model Tests")
struct PublicUserProfileModelTests {
    @Test("Decodes with all fields")
    func decodesWithAllFields() throws {
        let json = """
        {
            "id": "user123",
            "display_name": "John Doe",
            "href": "https://api.spotify.com/v1/users/user123",
            "uri": "spotify:user:user123",
            "type": "user",
            "external_urls": {
                "spotify": "https://open.spotify.com/user/user123"
            },
            "followers": {
                "href": null,
                "total": 100
            },
            "images": [
                {
                    "url": "https://i.scdn.co/image/ab67616d0000b273",
                    "height": 640,
                    "width": 640
                }
            ]
        }
        """.data(using: .utf8)!
        
        let profile: PublicUserProfile = try decodeModel(from: json)
        
        #expect(profile.id == "user123")
        #expect(profile.displayName == "John Doe")
        #expect(profile.href.absoluteString == "https://api.spotify.com/v1/users/user123")
        #expect(profile.uri == "spotify:user:user123")
        #expect(profile.type == "user")
        #expect(profile.externalUrls.spotify?.absoluteString == "https://open.spotify.com/user/user123")
        #expect(profile.followers.total == 100)
        #expect(profile.followers.href == nil)
        #expect(profile.images.count == 1)
        #expect(profile.images[0].url.absoluteString == "https://i.scdn.co/image/ab67616d0000b273")
    }
    
    @Test("Decodes without display name")
    func decodesWithoutDisplayName() throws {
        let json = """
        {
            "id": "user456",
            "display_name": null,
            "href": "https://api.spotify.com/v1/users/user456",
            "uri": "spotify:user:user456",
            "type": "user",
            "external_urls": {
                "spotify": "https://open.spotify.com/user/user456"
            },
            "followers": {
                "href": null,
                "total": 0
            },
            "images": []
        }
        """.data(using: .utf8)!
        
        let profile: PublicUserProfile = try decodeModel(from: json)
        
        #expect(profile.id == "user456")
        #expect(profile.displayName == nil)
        #expect(profile.type == "user")
        #expect(profile.followers.total == 0)
        #expect(profile.images.isEmpty)
    }
    
    @Test("Equatable works correctly")
    func equatableWorksCorrectly() {
        let profile1 = PublicUserProfile(
            id: "user1",
            displayName: "User One",
            href: URL(string: "https://api.spotify.com/v1/users/user1")!,
            uri: "spotify:user:user1",
            type: "user",
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/user/user1")),
            followers: SpotifyFollowers(href: nil, total: 50),
            images: []
        )
        
        let profile2 = PublicUserProfile(
            id: "user1",
            displayName: "User One",
            href: URL(string: "https://api.spotify.com/v1/users/user1")!,
            uri: "spotify:user:user1",
            type: "user",
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/user/user1")),
            followers: SpotifyFollowers(href: nil, total: 50),
            images: []
        )
        
        let profile3 = PublicUserProfile(
            id: "user2",
            displayName: "User Two",
            href: URL(string: "https://api.spotify.com/v1/users/user2")!,
            uri: "spotify:user:user2",
            type: "user",
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/user/user2")),
            followers: SpotifyFollowers(href: nil, total: 100),
            images: []
        )
        
        #expect(profile1 == profile2)
        #expect(profile1 != profile3)
    }
    
    @Test("Encodes correctly")
    func encodesCorrectly() throws {
        let profile = PublicUserProfile(
            id: "user789",
            displayName: "Test User",
            href: URL(string: "https://api.spotify.com/v1/users/user789")!,
            uri: "spotify:user:user789",
            type: "user",
            externalUrls: SpotifyExternalUrls(spotify: URL(string: "https://open.spotify.com/user/user789")),
            followers: SpotifyFollowers(href: nil, total: 25),
            images: []
        )
        
        let data = try encodeModel(profile)
        let decoded: PublicUserProfile = try decodeModel(from: data)
        
        #expect(decoded == profile)
    }
}

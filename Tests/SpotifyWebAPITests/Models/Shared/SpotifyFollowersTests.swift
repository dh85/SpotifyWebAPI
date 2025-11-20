import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite struct SpotifyFollowersTests {

    @Test
    func decodesWithNullHref() throws {
        let json = """
            {
                "href": null,
                "total": 1000
            }
            """
        let data = json.data(using: .utf8)!
        let followers: SpotifyFollowers = try decodeModel(from: data)

        #expect(followers.href == nil)
        #expect(followers.total == 1000)
    }

    @Test
    func decodesWithHref() throws {
        let json = """
            {
                "href": "https://api.spotify.com/v1/users/user123/followers",
                "total": 500
            }
            """
        let data = json.data(using: .utf8)!
        let followers: SpotifyFollowers = try decodeModel(from: data)

        #expect(
            followers.href?.absoluteString == "https://api.spotify.com/v1/users/user123/followers")
        #expect(followers.total == 500)
    }

    @Test
    func decodesWithZeroFollowers() throws {
        let json = """
            {
                "href": null,
                "total": 0
            }
            """
        let data = json.data(using: .utf8)!
        let followers: SpotifyFollowers = try decodeModel(from: data)

        #expect(followers.total == 0)
    }

    @Test
    func encodesCorrectly() throws {
        let followers = SpotifyFollowers(href: nil, total: 1500)
        let encoder = JSONEncoder()
        let data = try encoder.encode(followers)
        let decoded: SpotifyFollowers = try JSONDecoder().decode(
            SpotifyFollowers.self, from: data)

        #expect(decoded == followers)
    }

    @Test
    func equatableWorksCorrectly() {
        let followers1 = SpotifyFollowers(href: nil, total: 100)
        let followers2 = SpotifyFollowers(href: nil, total: 100)
        let followers3 = SpotifyFollowers(href: nil, total: 200)
        let followers4 = SpotifyFollowers(
            href: URL(string: "https://api.spotify.com/v1/test"), total: 100)

        #expect(followers1 == followers2)
        #expect(followers1 != followers3)
        #expect(followers1 != followers4)
    }
}

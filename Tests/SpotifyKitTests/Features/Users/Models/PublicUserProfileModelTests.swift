import Foundation
import Testing
@testable import SpotifyKit

@Suite("PublicUserProfile Model Tests")
struct PublicUserProfileModelTests {    
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

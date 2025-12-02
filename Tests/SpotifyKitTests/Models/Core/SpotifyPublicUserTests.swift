import Foundation
import Testing

@testable import SpotifyKit

@Suite struct SpotifyPublicUserTests {

    @Test
    func decodesPublicUserFixture() throws {
        let data = try TestDataLoader.load("public_user_profile")
        let user: SpotifyPublicUser = try decodeModel(from: data)

        #expect(user.id == "user123")
        #expect(user.displayName == "Test User")
        #expect(user.externalUrls?.spotify?.absoluteString == "https://open.spotify.com/user/user123")
        #expect(user.href?.absoluteString == "https://api.spotify.com/v1/users/user123")
    }
}

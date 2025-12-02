import Testing

@testable import SpotifyKit

@Suite("Validation Tests")
struct ValidationTests {

    @Test("Valid URIs pass validation")
    func validURIs() throws {
        // Standard format
        try validateURI("spotify:track:11dFghVXANMlKmJXsNCbNl")
        try validateURI("spotify:artist:0TnOYISbd1XYRBk9myaseg")
        try validateURI("spotify:album:4hDok0OAJd57SGIT8xuWJH")

        // User playlist format
        try validateURI("spotify:user:billboard.com:playlist:6UeSakyzhiEt4NB3UAd6KX")

        // Simple alphanumeric IDs
        try validateURI("spotify:track:12345")
        try validateURI("spotify:user:testuser")
    }

    @Test("Invalid URIs fail validation")
    func invalidURIs() {
        // Wrong scheme
        #expect(throws: SpotifyClientError.self) {
            try validateURI("http://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl")
        }

        // Missing ID
        #expect(throws: SpotifyClientError.self) {
            try validateURI("spotify:track")
        }

        // Empty ID
        #expect(throws: SpotifyClientError.self) {
            try validateURI("spotify:track:")
        }

        // Invalid characters in ID (non-alphanumeric)
        #expect(throws: SpotifyClientError.self) {
            try validateURI("spotify:track:invalid-char$")
        }

        // Too many components
        #expect(throws: SpotifyClientError.self) {
            try validateURI("spotify:track:id:extra")
        }

        // Empty string
        #expect(throws: SpotifyClientError.self) {
            try validateURI("")
        }
    }
}

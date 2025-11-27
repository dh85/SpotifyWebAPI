import Foundation
import Testing

@testable import SpotifyKit

@Suite struct HelpersTests {

    @Test
    @MainActor
    func performLibraryOperation_throwsError_forUnsupportedHTTPMethod() async throws {
        // Arrange
        let http = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        let client = SpotifyClient<UserAuthCapability>(
            backend: auth,
            httpClient: http
        )
        let ids: Set<String> = ["id1", "id2"]

        // Act & Assert
        await #expect(throws: SpotifyClientError.self) {
            try await performLibraryOperation(.get, endpoint: "/me/tracks", ids: ids, client: client)
        }
    }
}

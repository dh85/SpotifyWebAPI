import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// A mock implementation of `TokenGrantAuthenticator` for testing.
actor MockTokenAuthenticator: TokenGrantAuthenticator {

    private var token: SpotifyTokens
    var didInvalidatePrevious: Bool = false

    init(token: SpotifyTokens) {
        self.token = token
    }

    func setToken(_ newToken: SpotifyTokens) {
        self.token = newToken
    }

    /// Conforms to `TokenGrantAuthenticator`.
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
        self.didInvalidatePrevious = invalidatingPrevious

        // 1. If the client is telling us the last token was bad (401),
        //    then we must return a fresh one.
        if invalidatingPrevious {
            let refreshedToken = SpotifyTokens.mockValid
            self.token = refreshedToken  // Update internal state
            return refreshedToken
        }

        // 2. Otherwise (if invalidatingPrevious is false), we just return
        //    whatever token we're currently holding, even if it's expired.
        //    This simulates returning a cached token.
        return token
    }

    // (We don't need to implement loadPersistedTokens for these tests)
    func loadPersistedTokens() async throws -> SpotifyTokens? {
        return token
    }
}

/// A custom test error
enum TestError: Error, Equatable {
    case general(String)
}

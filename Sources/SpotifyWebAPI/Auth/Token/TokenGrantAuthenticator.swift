/// Can call public Spotify endpoints (no user context required).
public protocol PublicSpotifyCapability: Sendable {}

/// Can call both public and *user* endpoints.
public protocol UserSpotifyCapability: PublicSpotifyCapability {}

/// Marker type: this client has a real *user* attached (PKCE or Auth Code).
public enum UserAuthCapability: UserSpotifyCapability, Sendable {}

/// Marker type: this client is app-only (Client Credentials).
public enum AppOnlyAuthCapability: PublicSpotifyCapability, Sendable {}

protocol TokenGrantAuthenticator: Sendable {
    func loadPersistedTokens() async throws -> SpotifyTokens?

    /// Main operation: return a valid token (refresh / re-auth as needed).
    /// - Parameter invalidatingPrevious: If true, the authenticator should not
    ///   return a cached token and should force a refresh if possible.
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens
}

extension TokenGrantAuthenticator {
    /// Main operation: return a valid token.
    /// This default implementation calls the full method with `invalidatingPrevious: false`.
    func accessToken() async throws -> SpotifyTokens {
        try await accessToken(invalidatingPrevious: false)
    }
}

extension SpotifyPKCEAuthenticator: TokenGrantAuthenticator {
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
        try await refreshAccessTokenIfNeeded(invalidatingPrevious: invalidatingPrevious)
    }
}

extension SpotifyAuthorizationCodeAuthenticator: TokenGrantAuthenticator {
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
        try await refreshAccessTokenIfNeeded(invalidatingPrevious: invalidatingPrevious)
    }
}

extension SpotifyClientCredentialsAuthenticator: TokenGrantAuthenticator {
    func accessToken(invalidatingPrevious: Bool) async throws -> SpotifyTokens {
        try await appAccessToken(invalidatingPrevious: invalidatingPrevious)
    }
}

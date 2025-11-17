import Foundation

/// Defines an actor that can persist and load Spotify tokens.
protocol TokenPersisting: Actor {
    /// The underlying storage mechanism.
    var tokenStore: TokenStore { get }

    /// The in-memory token cache.
    var cachedTokens: SpotifyTokens? { get set }

    /// Loads tokens, checking the cache first, then the store.
    func loadPersistedTokens() async throws -> SpotifyTokens?

    /// Saves tokens to the cache and store.
    func persist(_ tokens: SpotifyTokens) async throws
}

// Provide a default implementation for all conformers.
extension TokenPersisting {
    public func loadPersistedTokens() async throws -> SpotifyTokens? {
        if let cachedTokens {
            return cachedTokens
        }
        let stored = try await tokenStore.load()
        cachedTokens = stored
        return stored
    }

    public func persist(_ tokens: SpotifyTokens) async throws {
        cachedTokens = tokens
        try await tokenStore.save(tokens)
    }
}

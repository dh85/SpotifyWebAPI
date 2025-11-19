import Foundation
import Testing

@testable import SpotifyWebAPI

actor MockTokenStore: TokenStore {
    private var storage: SpotifyTokens?
    private var shouldThrow = false
    
    func setShouldThrow(_ shouldThrow: Bool) {
        self.shouldThrow = shouldThrow
    }
    
    func load() async throws -> SpotifyTokens? {
        if shouldThrow { throw MockError.loadFailed }
        return storage
    }
    
    func save(_ tokens: SpotifyTokens) async throws {
        if shouldThrow { throw MockError.saveFailed }
        storage = tokens
    }
    
    func clear() async throws {
        if shouldThrow { throw MockError.clearFailed }
        storage = nil
    }
    
    enum MockError: Error {
        case loadFailed, saveFailed, clearFailed
    }
}

@Suite
struct MockTokenStoreTests {
    
    private func makeSampleTokens() -> SpotifyTokens {
        SpotifyTokens(
            accessToken: "ACCESS",
            refreshToken: "REFRESH",
            expiresAt: Date().addingTimeInterval(3600),
            scope: "user-read-email",
            tokenType: "Bearer"
        )
    }
    
    @Test
    func loadReturnsNilInitially() async throws {
        let store = MockTokenStore()
        let result = try await store.load()
        #expect(result == nil)
    }
    
    @Test
    func saveThenLoadReturnsSameTokens() async throws {
        let store = MockTokenStore()
        let tokens = makeSampleTokens()
        
        try await store.save(tokens)
        let loaded = try await store.load()
        
        #expect(loaded?.accessToken == tokens.accessToken)
        #expect(loaded?.refreshToken == tokens.refreshToken)
    }
    
    @Test
    func clearRemovesTokens() async throws {
        let store = MockTokenStore()
        let tokens = makeSampleTokens()
        
        try await store.save(tokens)
        try await store.clear()
        let result = try await store.load()
        
        #expect(result == nil)
    }
    
    @Test
    func saveThrowsWhenConfigured() async throws {
        let store = MockTokenStore()
        await store.setShouldThrow(true)
        
        await #expect(throws: MockTokenStore.MockError.saveFailed) {
            try await store.save(makeSampleTokens())
        }
    }
}
import Foundation
import Testing

@testable import SpotifyWebAPI

@Suite("Token Expiration Callback Tests")
@MainActor
struct TokenExpirationCallbackTests {

    actor CallbackTracker {
        var wasCalled = false
        var expiresIn: TimeInterval?
        var callCount = 0
        
        func markCalled() {
            wasCalled = true
        }
        
        func recordExpiration(_ time: TimeInterval) {
            expiresIn = time
        }
        
        func incrementCount() {
            callCount += 1
        }
    }

    @Test("Callback is called on token access")
    func callbackCalledOnAccess() async throws {
        let (client, http) = makeUserAuthClient()
        let tracker = CallbackTracker()
        
        await client.events.onTokenExpiring { _ in
            Task { @MainActor in
                await tracker.markCalled()
            }
        }
        
        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )
        
        _ = try await client.users.me()
        
        try await Task.sleep(for: .milliseconds(10))
        let called = await tracker.wasCalled
        #expect(called == true)
    }

    @Test("Callback receives correct expiration time")
    func callbackReceivesExpirationTime() async throws {
        let (client, http) = makeUserAuthClient()
        let tracker = CallbackTracker()
        
        await client.events.onTokenExpiring { expiresIn in
            Task { @MainActor in
                await tracker.recordExpiration(expiresIn)
            }
        }
        
        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )
        
        _ = try await client.users.me()
        
        try await Task.sleep(for: .milliseconds(10))
        let expiresIn = await tracker.expiresIn
        #expect(expiresIn != nil)
        #expect(expiresIn! > 0)
    }

    @Test("Callback not called when not set")
    func callbackNotCalledWhenNotSet() async throws {
        let (client, http) = makeUserAuthClient()
        
        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )
        
        _ = try await client.users.me()
        
        // Test passes if no crash occurs
        #expect(Bool(true))
    }

    @Test("Callback called on multiple requests")
    func callbackCalledMultipleTimes() async throws {
        let (client, http) = makeUserAuthClient()
        let tracker = CallbackTracker()
        
        await client.events.onTokenExpiring { _ in
            Task { @MainActor in
                await tracker.incrementCount()
            }
        }
        
        await http.addMockResponse(
            data: try TestDataLoader.load("current_user_profile"),
            statusCode: 200
        )
        await http.addMockResponse(
            data: try TestDataLoader.load("album_full"),
            statusCode: 200
        )
        
        _ = try await client.users.me()
        _ = try await client.albums.get("test")
        
        try await Task.sleep(for: .milliseconds(10))
        let count = await tracker.callCount
        #expect(count == 2)
    }
}

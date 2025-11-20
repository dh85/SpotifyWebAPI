import Foundation
import Testing
@testable import SpotifyWebAPI

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@Suite
@MainActor
struct UsersServiceTests {
    
    // MARK: - Public Access Tests
    
    @Test
    func getBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let userData = try TestDataLoader.load("public_user_profile.json")
        await http.addMockResponse(data: userData, statusCode: 200)
        
        let profile = try await client.users.get("user123")
        
        #expect(profile.id == "user123")
        expectRequest(await http.firstRequest, path: "/v1/users/user123", method: "GET")
    }
    
    @Test
    func checkFollowingPlaylistBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = "[true, false, true]".data(using: .utf8)!
        await http.addMockResponse(data: checkData, statusCode: 200)
        
        let userIDs: Set<String> = ["user1", "user2", "user3"]
        let results = try await client.users.checkFollowing(playlist: "playlist123", users: userIDs)
        
        #expect(results.count == 3)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/playlists/playlist123/followers/contains", method: "GET")
        #expect(extractIDs(from: request?.url) == userIDs)
    }
    
    @Test
    func checkFollowingPlaylistThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 5") {
            _ = try await client.users.checkFollowing(playlist: "playlist123", users: makeIDs(count: 6))
        }
    }
    
    // MARK: - User Access Tests
    
    @Test
    func meBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let profileData = try TestDataLoader.load("current_user_profile.json")
        await http.addMockResponse(data: profileData, statusCode: 200)
        
        let profile = try await client.users.me()
        
        #expect(profile.id == "mockuser")
        expectRequest(await http.firstRequest, path: "/v1/me", method: "GET")
    }
    
    @Test
    func topArtistsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let artistsData = try TestDataLoader.load("top_artists.json")
        await http.addMockResponse(data: artistsData, statusCode: 200)
        
        let page = try await client.users.topArtists(range: .shortTerm, limit: 10, offset: 5)
        
        #expect(page.items.count > 0)
        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/me/top/artists", method: "GET",
            queryContains: "time_range=short_term", "limit=10", "offset=5"
        )
    }
    
    @Test
    func topArtistsUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let artistsData = try TestDataLoader.load("top_artists.json")
        await http.addMockResponse(data: artistsData, statusCode: 200)
        
        _ = try await client.users.topArtists()
        
        expectPaginationDefaults(await http.firstRequest)
    }
    
    @Test
    func topArtistsThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.users.topArtists(limit: limit)
        }
    }
    
    @Test
    func topTracksBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("top_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)
        
        let page = try await client.users.topTracks(range: .longTerm, limit: 15, offset: 10)
        
        #expect(page.items.count > 0)
        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/me/top/tracks", method: "GET",
            queryContains: "time_range=long_term", "limit=15", "offset=10"
        )
    }
    
    @Test
    func topTracksUsesDefaultPagination() async throws {
        let (client, http) = makeUserAuthClient()
        let tracksData = try TestDataLoader.load("top_tracks.json")
        await http.addMockResponse(data: tracksData, statusCode: 200)
        
        _ = try await client.users.topTracks()
        
        expectPaginationDefaults(await http.firstRequest)
    }
    
    @Test
    func topTracksThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.users.topTracks(limit: limit)
        }
    }
    
    @Test
    func followedArtistsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let artistsData = try TestDataLoader.load("followed_artists.json")
        await http.addMockResponse(data: artistsData, statusCode: 200)
        
        let page = try await client.users.followedArtists(limit: 10, after: "artist123")
        
        #expect(page.items.count > 0)
        let request = await http.firstRequest
        expectRequest(
            request, path: "/v1/me/following", method: "GET",
            queryContains: "type=artist", "limit=10", "after=artist123"
        )
    }
    
    @Test
    func followedArtistsUsesDefaultLimit() async throws {
        let (client, http) = makeUserAuthClient()
        let artistsData = try TestDataLoader.load("followed_artists.json")
        await http.addMockResponse(data: artistsData, statusCode: 200)
        
        _ = try await client.users.followedArtists()
        
        let request = await http.firstRequest
        #expect(request?.url?.query()?.contains("limit=20") == true)
    }
    
    @Test
    func followedArtistsThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.users.followedArtists(limit: limit)
        }
    }
    
    @Test
    func followArtistsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)
        let artistIDs = makeIDs(prefix: "artist_", count: 10)
        
        try await client.users.follow(artists: artistIDs)
        
        let request = await http.firstRequest
        expectIDsInBody(request, path: "/v1/me/following", method: "PUT", expectedIDs: artistIDs)
        #expect(request?.url?.query()?.contains("type=artist") == true)
    }
    
    @Test
    func followArtistsThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            try await client.users.follow(artists: makeIDs(count: 51))
        }
    }
    
    @Test
    func followUsersBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)
        let userIDs = makeIDs(prefix: "user_", count: 10)
        
        try await client.users.follow(users: userIDs)
        
        let request = await http.firstRequest
        expectIDsInBody(request, path: "/v1/me/following", method: "PUT", expectedIDs: userIDs)
        #expect(request?.url?.query()?.contains("type=user") == true)
    }
    
    @Test
    func unfollowArtistsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)
        let artistIDs = makeIDs(prefix: "artist_", count: 10)
        
        try await client.users.unfollow(artists: artistIDs)
        
        let request = await http.firstRequest
        expectIDsInBody(request, path: "/v1/me/following", method: "DELETE", expectedIDs: artistIDs)
        #expect(request?.url?.query()?.contains("type=artist") == true)
    }
    
    @Test
    func unfollowArtistsThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            try await client.users.unfollow(artists: makeIDs(count: 51))
        }
    }
    
    @Test
    func unfollowUsersBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 204)
        let userIDs = makeIDs(prefix: "user_", count: 10)
        
        try await client.users.unfollow(users: userIDs)
        
        let request = await http.firstRequest
        expectIDsInBody(request, path: "/v1/me/following", method: "DELETE", expectedIDs: userIDs)
        #expect(request?.url?.query()?.contains("type=user") == true)
    }
    
    @Test
    func checkFollowingArtistsBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = "[true, false, true]".data(using: .utf8)!
        await http.addMockResponse(data: checkData, statusCode: 200)
        
        let artistIDs = makeIDs(prefix: "artist_", count: 3)
        let results = try await client.users.checkFollowing(artists: artistIDs)
        
        #expect(results.count == 3)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/following/contains", method: "GET", queryContains: "type=artist")
        #expect(extractIDs(from: request?.url) == artistIDs)
    }
    
    @Test
    func checkFollowingArtistsThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectIDLimitError(count: 51) {
            _ = try await client.users.checkFollowing(artists: makeIDs(count: 51))
        }
    }
    
    @Test
    func checkFollowingUsersBuildsCorrectRequest() async throws {
        let (client, http) = makeUserAuthClient()
        let checkData = "[true, false]".data(using: .utf8)!
        await http.addMockResponse(data: checkData, statusCode: 200)
        
        let userIDs = makeIDs(prefix: "user_", count: 2)
        let results = try await client.users.checkFollowing(users: userIDs)
        
        #expect(results.count == 2)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/following/contains", method: "GET", queryContains: "type=user")
        #expect(extractIDs(from: request?.url) == userIDs)
    }
    
    // MARK: - Helper Methods
    
    private func expectIDLimitError(count: Int, operation: @escaping () async throws -> Void) async {
        await expectInvalidRequest(reasonContains: "Maximum of 50", operation: operation)
    }
}

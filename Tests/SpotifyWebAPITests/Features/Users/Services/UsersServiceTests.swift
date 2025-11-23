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
        try await withMockServiceClient(fixture: "public_user_profile.json") { client, http in
            let profile = try await client.users.get("user123")

            #expect(profile.id == "user123")
            expectRequest(await http.firstRequest, path: "/v1/users/user123", method: "GET")
        }
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
            _ = try await client.users.checkFollowing(
                playlist: "playlist123", users: makeIDs(count: 6))
        }
    }

    // MARK: - User Access Tests

    @Test
    func meBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "current_user_profile.json") { client, http in
            let profile = try await client.users.me()

            #expect(profile.id == "mockuser")
            expectRequest(await http.firstRequest, path: "/v1/me", method: "GET")
        }
    }

    @Test
    func topArtistsBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "top_artists.json") { client, http in
            let page = try await client.users.topArtists(range: .shortTerm, limit: 10, offset: 5)

            #expect(page.items.count > 0)
            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/top/artists", method: "GET",
                queryContains: "time_range=short_term", "limit=10", "offset=5"
            )
        }
    }

    @Test
    func topArtistsUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "top_artists.json") { client in
            _ = try await client.users.topArtists()
        }
    }

    @Test
    func topArtistsThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.users.topArtists(limit: limit)
        }
    }

    @Test
    func streamTopArtistPagesBuildsRequests() async throws {
        let (client, http) = makeUserAuthClient()
        let response = try makePaginatedResponse(
            fixture: "top_artists.json",
            of: Artist.self,
            offset: 0,
            limit: 30,
            total: 30,
            hasNext: false
        )
        await http.addMockResponse(data: response, statusCode: 200)

        var offsets: [Int] = []
        let stream = await client.users.streamTopArtistPages(
            range: .shortTerm,
            pageSize: 30,
            maxPages: 1
        )
        for try await page in stream {
            offsets.append(page.offset)
        }

        #expect(offsets == [0])
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/top/artists", method: "GET")
        #expect(request?.url?.query()?.contains("time_range=short_term") == true)
        #expect(request?.url?.query()?.contains("limit=30") == true)
    }

    @Test
    func streamTopArtistsEmitsItems() async throws {
        let (client, http) = makeUserAuthClient()
        let response = try makePaginatedResponse(
            fixture: "top_artists.json",
            of: Artist.self,
            offset: 0,
            limit: 40,
            total: 40,
            hasNext: false
        )
        await http.addMockResponse(data: response, statusCode: 200)

        var artistIDs: [String] = []
        let stream = await client.users.streamTopArtists(
            range: .longTerm,
            pageSize: 40,
            maxItems: 80
        )
        for try await artist in stream {
            if let id = artist.id {
                artistIDs.append(id)
            }
        }

        #expect(artistIDs.isEmpty == false)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/top/artists", method: "GET")
        #expect(request?.url?.query()?.contains("time_range=long_term") == true)
        #expect(request?.url?.query()?.contains("limit=40") == true)
    }

    @Test
    func topTracksBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "top_tracks.json") { client, http in
            let page = try await client.users.topTracks(range: .longTerm, limit: 15, offset: 10)

            #expect(page.items.count > 0)
            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/top/tracks", method: "GET",
                queryContains: "time_range=long_term", "limit=15", "offset=10"
            )
        }
    }

    @Test
    func topTracksUsesDefaultPagination() async throws {
        try await expectDefaultPagination(fixture: "top_tracks.json") { client in
            _ = try await client.users.topTracks()
        }
    }

    @Test
    func topTracksThrowsErrorWhenLimitOutOfBounds() async throws {
        let (client, _) = makeUserAuthClient()
        await expectLimitErrors { limit in
            _ = try await client.users.topTracks(limit: limit)
        }
    }

    @Test
    func streamTopTrackPagesBuildsRequests() async throws {
        let (client, http) = makeUserAuthClient()
        let response = try makePaginatedResponse(
            fixture: "top_tracks.json",
            of: Track.self,
            offset: 0,
            limit: 35,
            total: 35,
            hasNext: false
        )
        await http.addMockResponse(data: response, statusCode: 200)

        var offsets: [Int] = []
        let stream = await client.users.streamTopTrackPages(
            range: .longTerm,
            pageSize: 35,
            maxPages: 1
        )
        for try await page in stream {
            offsets.append(page.offset)
        }

        #expect(offsets == [0])
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/top/tracks", method: "GET")
        #expect(request?.url?.query()?.contains("time_range=long_term") == true)
        #expect(request?.url?.query()?.contains("limit=35") == true)
    }

    @Test
    func streamTopTracksEmitsItems() async throws {
        let (client, http) = makeUserAuthClient()
        let response = try makePaginatedResponse(
            fixture: "top_tracks.json",
            of: Track.self,
            offset: 0,
            limit: 45,
            total: 45,
            hasNext: false
        )
        await http.addMockResponse(data: response, statusCode: 200)

        var trackIDs: [String] = []
        let stream = await client.users.streamTopTracks(
            range: .shortTerm,
            pageSize: 45,
            maxItems: 45
        )
        for try await track in stream {
            if let id = track.id {
                trackIDs.append(id)
            }
        }

        #expect(trackIDs.isEmpty == false)
        let request = await http.firstRequest
        expectRequest(request, path: "/v1/me/top/tracks", method: "GET")
        #expect(request?.url?.query()?.contains("time_range=short_term") == true)
        #expect(request?.url?.query()?.contains("limit=45") == true)
    }

    @Test
    func followedArtistsBuildsCorrectRequest() async throws {
        try await withMockServiceClient(fixture: "followed_artists.json") { client, http in
            let page = try await client.users.followedArtists(limit: 10, after: "artist123")

            #expect(page.items.count > 0)
            let request = await http.firstRequest
            expectRequest(
                request, path: "/v1/me/following", method: "GET",
                queryContains: "type=artist", "limit=10", "after=artist123"
            )
        }
    }

    @Test
    func followedArtistsUsesDefaultLimit() async throws {
        try await withMockServiceClient(fixture: "followed_artists.json") { client, http in
            _ = try await client.users.followedArtists()

            let request = await http.firstRequest
            #expect(request?.url?.query()?.contains("limit=20") == true)
        }
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
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
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
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
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
        expectRequest(
            request, path: "/v1/me/following/contains", method: "GET", queryContains: "type=artist")
        #expect(extractIDs(from: request?.url) == artistIDs)
    }

    @Test
    func checkFollowingArtistsThrowsErrorWhenIDLimitExceeded() async throws {
        let (client, _) = makeUserAuthClient()
        await expectInvalidRequest(reasonContains: "Maximum of 50") {
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
        expectRequest(
            request, path: "/v1/me/following/contains", method: "GET", queryContains: "type=user")
        #expect(extractIDs(from: request?.url) == userIDs)
    }

}

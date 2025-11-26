#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyWebAPI

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("Users Service Combine Tests")
    @MainActor
    struct UsersServiceCombineTests {

        @Test("mePublisher emits profile")
        func mePublisherEmitsProfile() async throws {
            let profile = try await assertPublisherRequest(
                fixture: "current_user_profile.json",
                path: "/v1/me",
                method: "GET"
            ) { client in
                let users = await client.users
                return users.mePublisher()
            }

            #expect(profile.id == "mockuser")
        }

        @Test("topArtistsPublisher mirrors async implementation")
        func topArtistsPublisherBuildsCorrectRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "top_artists.json",
                path: "/v1/me/top/artists",
                method: "GET",
                queryContains: [
                    "time_range=short_term",
                    "limit=10",
                    "offset=5",
                ]
            ) { client in
                let users = await client.users
                return users.topArtistsPublisher(timeRange: .shortTerm, limit: 10, offset: 5)
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("followPublisher surfaces validation errors")
        func followPublisherPropagatesValidationErrors() async {
            let (client, _) = makeUserAuthClient()
            let users = await client.users
            let ids = makeIDs(count: 51)
            let publisher = users.followPublisher(artists: ids)

            await expectInvalidRequest(reasonContains: "Maximum of 50") {
                _ = try await awaitFirstValue(publisher)
            }
        }

        @Test("getPublisher emits public profile")
        func getPublisherEmitsPublicProfile() async throws {
            let profile = try await assertPublisherRequest(
                fixture: "public_user_profile.json",
                path: "/v1/users/user123",
                method: "GET"
            ) { client in
                let users = await client.users
                return users.getPublisher("user123")
            }

            #expect(profile.id == "user123")
        }

        @Test("checkFollowingPlaylistPublisher builds correct request")
        func checkFollowingPlaylistPublisherBuildsRequest() async throws {
            let (client, http) = makeUserAuthClient()
            let response = "[true,false]".data(using: .utf8)!
            await http.addMockResponse(data: response, statusCode: 200)

            let users = await client.users
            let ids: Set<String> = ["userA", "userB"]
            let results = try await awaitFirstValue(
                users.checkFollowingPublisher(playlist: "playlist123", users: ids)
            )

            #expect(results == [true, false])
            let request = await http.firstRequest
            expectRequest(
                request,
                path: "/v1/playlists/playlist123/followers/contains",
                method: "GET"
            )
            #expect(extractIDs(from: request?.url) == ids)
        }

        @Test("topTracksPublisher mirrors async implementation")
        func topTracksPublisherBuildsCorrectRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "top_tracks.json",
                path: "/v1/me/top/tracks",
                method: "GET",
                queryContains: [
                    "time_range=long_term",
                    "limit=15",
                    "offset=2",
                ]
            ) { client in
                let users = await client.users
                return users.topTracksPublisher(timeRange: .longTerm, limit: 15, offset: 2)
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("followedArtistsPublisher builds correct request")
        func followedArtistsPublisherBuildsCorrectRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "followed_artists.json",
                path: "/v1/me/following",
                method: "GET",
                queryContains: [
                    "type=artist",
                    "limit=10",
                    "after=artist123",
                ]
            ) { client in
                let users = await client.users
                return users.followedArtistsPublisher(limit: 10, after: "artist123")
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("followPublisher artists builds correct request")
        func followPublisherArtistsBuildsRequest() async throws {
            let ids = makeIDs(prefix: "artist_", count: 5)
            try await assertIDsMutationPublisher(
                path: "/v1/me/following",
                method: "PUT",
                ids: ids,
                queryContains: ["type=artist"],
                statusCode: 204
            ) { client, ids in
                let users = await client.users
                return users.followPublisher(artists: ids)
            }
        }

        @Test("followPublisher users builds correct request")
        func followPublisherUsersBuildsRequest() async throws {
            let ids = makeIDs(prefix: "user_", count: 3)
            try await assertIDsMutationPublisher(
                path: "/v1/me/following",
                method: "PUT",
                ids: ids,
                queryContains: ["type=user"],
                statusCode: 204
            ) { client, ids in
                let users = await client.users
                return users.followPublisher(users: ids)
            }
        }

        @Test("unfollowPublisher artists builds correct request")
        func unfollowPublisherArtistsBuildsRequest() async throws {
            let ids = makeIDs(prefix: "artist_", count: 4)
            try await assertIDsMutationPublisher(
                path: "/v1/me/following",
                method: "DELETE",
                ids: ids,
                queryContains: ["type=artist"],
                statusCode: 204
            ) { client, ids in
                let users = await client.users
                return users.unfollowPublisher(artists: ids)
            }
        }

        @Test("unfollowPublisher users builds correct request")
        func unfollowPublisherUsersBuildsRequest() async throws {
            let ids = makeIDs(prefix: "user_", count: 4)
            try await assertIDsMutationPublisher(
                path: "/v1/me/following",
                method: "DELETE",
                ids: ids,
                queryContains: ["type=user"],
                statusCode: 204
            ) { client, ids in
                let users = await client.users
                return users.unfollowPublisher(users: ids)
            }
        }

        @Test("checkFollowingPublisher artists builds correct request")
        func checkFollowingArtistsPublisherBuildsRequest() async throws {
            let (client, http) = makeUserAuthClient()
            let response = "[true,false,true]".data(using: .utf8)!
            await http.addMockResponse(data: response, statusCode: 200)

            let users = await client.users
            let ids = makeIDs(prefix: "artist_", count: 3)
            let result = try await awaitFirstValue(users.checkFollowingPublisher(artists: ids))

            #expect(result == [true, false, true])
            let request = await http.firstRequest
            expectRequest(
                request,
                path: "/v1/me/following/contains",
                method: "GET",
                queryContains: "type=artist"
            )
            #expect(extractIDs(from: request?.url) == ids)
        }

        @Test("checkFollowingPublisher users builds correct request")
        func checkFollowingUsersPublisherBuildsRequest() async throws {
            let (client, http) = makeUserAuthClient()
            let response = "[false,true]".data(using: .utf8)!
            await http.addMockResponse(data: response, statusCode: 200)

            let users = await client.users
            let ids = makeIDs(prefix: "user_", count: 2)
            let result = try await awaitFirstValue(users.checkFollowingPublisher(users: ids))

            #expect(result == [false, true])
            let request = await http.firstRequest
            expectRequest(
                request,
                path: "/v1/me/following/contains",
                method: "GET",
                queryContains: "type=user"
            )
            #expect(extractIDs(from: request?.url) == ids)
        }
    }

#endif

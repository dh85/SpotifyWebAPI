#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyKit

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("Episodes Service Combine Tests")
    @MainActor
    struct EpisodesServiceCombineTests {

        @Test("getPublisher emits episode")
        func getPublisherEmitsEpisode() async throws {
            let episode = try await assertPublisherRequest(
                fixture: "episode_full.json",
                path: "/v1/episodes/episode123",
                method: "GET",
                queryContains: ["market=US"]
            ) { client in
                let episodes = client.episodes
                return episodes.getPublisher("episode123", market: "US")
            }

            #expect(episode.name != nil)
        }

        @Test("severalPublisher builds correct request")
        func severalPublisherBuildsRequest() async throws {
            let ids: Set<String> = ["e1", "e2", "e3"]
            let episodes = try await assertPublisherRequest(
                fixture: "episodes_several.json",
                path: "/v1/episodes",
                method: "GET",
                queryContains: ["market=ES"],
                verifyRequest: { request in
                    #expect(extractIDs(from: request?.url) == ids)
                }
            ) { client in
                let episodesService = client.episodes
                return episodesService.severalPublisher(ids: ids, market: "ES")
            }

            #expect(episodes.count == ids.count)
        }

        @Test("severalPublisher validates ID limit")
        func severalPublisherValidatesLimit() async {
            let (client, _) = makeUserAuthClient()
            let episodes = client.episodes

            await expectPublisherIDBatchLimit(max: 50) { ids in
                episodes.severalPublisher(ids: ids)
            }
        }

        @Test("savedPublisher builds correct request")
        func savedPublisherBuildsRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "episodes_saved.json",
                path: "/v1/me/episodes",
                method: "GET",
                queryContains: ["limit=10", "offset=5"],
                verifyRequest: { request in
                    expectMarketParameter(request, market: "DE")
                }
            ) { client in
                let episodes = client.episodes
                return episodes.savedPublisher(limit: 10, offset: 5, market: "DE")
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("savedPublisher validates limit")
        func savedPublisherValidatesLimit() async {
            let (client, _) = makeUserAuthClient()
            let episodes = client.episodes

            await expectPublisherLimitValidation { limit in
                episodes.savedPublisher(limit: limit)
            }
        }

        @Test("allSavedEpisodesPublisher aggregates pages")
        func allSavedEpisodesPublisherAggregatesPages() async throws {
            try await assertAggregatesPages(
                fixture: "episodes_saved.json",
                of: SavedEpisode.self,
                verifyFirstRequest: { request in
                    expectSavedStreamRequest(request, path: "/v1/me/episodes", market: "CA")
                }
            ) { client in
                let episodes = client.episodes
                return episodes.allSavedEpisodesPublisher(market: "CA", maxItems: 100)
            }
        }

        @Test("savePublisher builds correct request")
        func savePublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 20)
            try await assertIDsMutationPublisher(
                path: "/v1/me/episodes",
                method: "PUT",
                ids: ids
            ) { client, ids in
                let episodes = client.episodes
                return episodes.savePublisher(ids)
            }
        }

        @Test("savePublisher validates limit")
        func savePublisherValidatesLimit() async {
            let (client, _) = makeUserAuthClient()
            let episodes = client.episodes

            await expectPublisherIDBatchLimit(max: 50) { ids in
                episodes.savePublisher(ids)
            }
        }

        @Test("removePublisher builds correct request")
        func removePublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 15)
            try await assertIDsMutationPublisher(
                path: "/v1/me/episodes",
                method: "DELETE",
                ids: ids
            ) { client, ids in
                let episodes = client.episodes
                return episodes.removePublisher(ids)
            }
        }

        @Test("checkSavedPublisher builds correct request")
        func checkSavedPublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 10)
            let result = try await assertPublisherRequest(
                fixture: "check_saved_episodes.json",
                path: "/v1/me/episodes/contains",
                method: "GET",
                verifyRequest: { request in
                    #expect(extractIDs(from: request?.url) == ids)
                }
            ) { client in
                let episodes = client.episodes
                return episodes.checkSavedPublisher(ids)
            }

            #expect(result == [false, false, true])
        }
    }

#endif

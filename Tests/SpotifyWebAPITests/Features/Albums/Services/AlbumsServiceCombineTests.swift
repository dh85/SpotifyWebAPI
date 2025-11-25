#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyWebAPI

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("Albums Service Combine Tests")
    @MainActor
    struct AlbumsServiceCombineTests {

        @Test("getPublisher emits album")
        func getPublisherEmitsAlbum() async throws {
            let album = try await assertPublisherRequest(
                fixture: "album_full.json",
                path: "/v1/albums/album123",
                method: "GET",
                queryContains: ["market=US"]
            ) { client in
                let albums = client.albums
                return albums.getPublisher("album123", market: "US")
            }

            #expect(album.name.isEmpty == false)
        }

        @Test("severalPublisher builds correct request")
        func severalPublisherBuildsRequest() async throws {
            let ids: Set<String> = ["a1", "a2", "a3"]
            let albums = try await assertPublisherRequest(
                fixture: "albums_several.json",
                path: "/v1/albums",
                method: "GET",
                queryContains: ["market=SE"],
                verifyRequest: { request in
                    #expect(extractIDs(from: request?.url) == ids)
                }
            ) { client in
                let albumsService = client.albums
                return albumsService.severalPublisher(ids: ids, market: "SE")
            }

            #expect(albums.isEmpty == false)
        }

        @Test("severalPublisher validates ID limits")
        func severalPublisherValidatesLimits() async {
            let (client, _) = makeUserAuthClient()
            let albums = client.albums

            await expectPublisherIDBatchLimit(max: 20) { ids in
                albums.severalPublisher(ids: ids)
            }
        }

        @Test("tracksPublisher builds correct request")
        func tracksPublisherBuildsRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "album_tracks.json",
                path: "/v1/albums/album123/tracks",
                method: "GET",
                queryContains: ["limit=15", "offset=2"],
                verifyRequest: { request in
                    expectMarketParameter(request, market: "GB")
                }
            ) { client in
                let albums = client.albums
                return albums.tracksPublisher("album123", market: "GB", limit: 15, offset: 2)
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("savedPublisher builds correct request")
        func savedPublisherBuildsRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "albums_saved.json",
                path: "/v1/me/albums",
                method: "GET",
                queryContains: ["limit=10", "offset=5"]
            ) { client in
                let albumsService = client.albums
                return albumsService.savedPublisher(limit: 10, offset: 5)
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("tracksPublisher validates limits")
        func tracksPublisherValidatesLimits() async {
            let (client, _) = makeUserAuthClient()
            let albums = client.albums

            await expectPublisherLimitValidation { limit in
                albums.tracksPublisher("album123", limit: limit)
            }
        }

        @Test("allSavedAlbumsPublisher aggregates pages")
        func allSavedAlbumsPublisherAggregatesPages() async throws {
            try await assertAggregatesPages(
                fixture: "albums_saved.json",
                of: SavedAlbum.self
            ) { client in
                let albumsService = client.albums
                return albumsService.allSavedAlbumsPublisher()
            }
        }

        @Test("savePublisher builds correct request")
        func savePublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 20)
            try await assertIDsMutationPublisher(
                path: "/v1/me/albums",
                method: "PUT",
                ids: ids
            ) { client, ids in
                let albumsService = client.albums
                return albumsService.savePublisher(ids)
            }
        }

        @Test("savePublisher propagates validation errors")
        func savePublisherValidationErrors() async {
            let (client, _) = makeUserAuthClient()
            let albumsService = client.albums

            await assertIDBatchTooLarge(
                maxAllowed: 20,
                reasonContains: "Maximum of 20"
            ) { ids in
                _ = try await awaitFirstValue(albumsService.savePublisher(ids))
            }
        }

        @Test("removePublisher builds correct request")
        func removePublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 10)
            try await assertIDsMutationPublisher(
                path: "/v1/me/albums",
                method: "DELETE",
                ids: ids
            ) { client, ids in
                let albums = client.albums
                return albums.removePublisher(ids)
            }
        }

        @Test("checkSavedPublisher builds correct request")
        func checkSavedPublisherBuildsRequest() async throws {
            let ids = makeIDs(count: 20)
            let result = try await assertPublisherRequest(
                fixture: "check_saved_albums.json",
                path: "/v1/me/albums/contains",
                method: "GET",
                verifyRequest: { request in
                    #expect(extractIDs(from: request?.url) == ids)
                }
            ) { client in
                let albums = client.albums
                return albums.checkSavedPublisher(ids)
            }

            #expect(result.count == 20)
        }
    }

#endif

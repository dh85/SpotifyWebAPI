#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyKit

    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif

    @Suite("Artists Service Combine Tests")
    @MainActor
    struct ArtistsServiceCombineTests {

        @Test("getPublisher emits artist")
        func getPublisherEmitsArtist() async throws {
            let artist = try await assertPublisherRequest(
                fixture: "artist_full.json",
                path: "/v1/artists/artist123",
                method: "GET"
            ) { client in
                let artists = await client.artists
                return artists.getPublisher("artist123")
            }

            #expect(artist.name.isEmpty == false)
        }

        @Test("severalPublisher builds correct request")
        func severalPublisherBuildsRequest() async throws {
            let ids: Set<String> = ["a1", "a2", "a3"]
            let artists = try await assertPublisherRequest(
                fixture: "artists_several.json",
                path: "/v1/artists",
                method: "GET",
                verifyRequest: { request in
                    #expect(extractIDs(from: request?.url) == ids)
                }
            ) { client in
                let artistsService = await client.artists
                return artistsService.severalPublisher(ids: ids)
            }

            #expect(artists.count == 3)
        }

        @Test("severalPublisher surfaces validation errors")
        func severalPublisherValidationErrors() async {
            let (client, _) = makeUserAuthClient()
            let artistsService = await client.artists

            await expectPublisherIDBatchLimit(max: 50) { ids in
                artistsService.severalPublisher(ids: ids)
            }
        }

        @Test("albumsPublisher builds correct request")
        func albumsPublisherBuildsRequest() async throws {
            let page = try await assertPublisherRequest(
                fixture: "artist_albums.json",
                path: "/v1/artists/artist123/albums",
                method: "GET",
                queryContains: [
                    "market=US",
                    "limit=15",
                    "offset=5",
                    "include_groups=appears_on,single",
                ]
            ) { client in
                let artists = await client.artists
                return artists.albumsPublisher(
                    for: "artist123",
                    includeGroups: [.single, .appearsOn],
                    market: "US",
                    limit: 15,
                    offset: 5
                )
            }

            #expect(page.items.isEmpty == false)
        }

        @Test("albumsPublisher strips empty include groups")
        func albumsPublisherStripsEmptyGroups() async throws {
            _ = try await assertPublisherRequest(
                fixture: "artist_albums.json",
                path: "/v1/artists/artist123/albums",
                method: "GET",
                queryContains: ["market=ES"],
                verifyRequest: { request in
                    let query = request?.url?.query()
                    #expect(query?.contains("include_groups=") == false)
                }
            ) { client in
                let artists = await client.artists
                return artists.albumsPublisher(
                    for: "artist123",
                    includeGroups: [],
                    market: "ES"
                )
            }
        }

        @Test("albumsPublisher validates limits")
        func albumsPublisherValidatesLimits() async {
            let (client, _) = makeUserAuthClient()
            let artists = await client.artists

            await expectPublisherLimitValidation { limit in
                artists.albumsPublisher(for: "artist123", limit: limit)
            }
        }

        @Test("topTracksPublisher builds correct request")
        func topTracksPublisherBuildsRequest() async throws {
            let tracks = try await assertPublisherRequest(
                fixture: "artist_top_tracks.json",
                path: "/v1/artists/artist123/top-tracks",
                method: "GET",
                queryContains: ["market=GB"]
            ) { client in
                let artists = await client.artists
                return artists.topTracksPublisher(for: "artist123", market: "GB")
            }

            #expect(tracks.isEmpty == false)
        }
    }

#endif

#if canImport(Combine)
    import Combine
    import Foundation
    import Testing

    @testable import SpotifyWebAPI

    @Suite
    @MainActor
    struct PublisherGeneratorsTests {

        @Test("makePublisher emits values")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherEmitsValues() async throws {
            let (client, http) = makeUserAuthClient()
            await http.addMockResponse(
                data: makeJSONData(#"{"devices": []}"#),
                statusCode: 200
            )

            let devices = try await awaitFirstValue(client.player.devicesPublisher())
            #expect(devices.isEmpty)
        }

        @Test("makePublisher propagates errors")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherPropagatesErrors() async {
            // Disable network recovery to avoid retry delays
            let config = SpotifyClientConfiguration(networkRecovery: .disabled)
            let (client, http) = makeUserAuthClient(configuration: config)
            await http.addMockResponse(
                data: makeJSONData(#"{"error": {"status": 500, "message": "Internal Error"}}"#),
                statusCode: 500
            )

            do {
                _ = try await awaitFirstValue(client.player.devicesPublisher())
                Issue.record("Expected error to be thrown")
            } catch {
                // Expected
            }
        }

        @Test("makePublisher cancels underlying task when subscription cancels")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherCancelsUnderlyingTask() async throws {
            let (client, _) = makeUserAuthClient()

            var cancellables = Set<AnyCancellable>()

            client.player.devicesPublisher()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)

            // Cancel immediately
            cancellables.removeAll()

            // Give some time for cancellation to propagate
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms

            // The request should be cancelled, though we can't easily verify
            // the internal task cancellation without exposing internals
        }

        @Test("makePublisher with one parameter")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherWithOneParameter() async throws {
            let (client, http) = makeUserAuthClient()
            let albumJSON = makeAlbumJSON(
                id: "album123",
                name: "Test Album",
                artistName: "Test Artist",
                totalTracks: 10,
                popularity: 50
            )
            await http.addMockResponse(
                data: albumJSON,
                statusCode: 200
            )

            let album = try await awaitFirstValue(client.albums.getPublisher("album123"))
            #expect(album.id == "album123")
            #expect(album.name == "Test Album")
        }

        @Test("makePublisher with two parameters")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherWithTwoParameters() async throws {
            let (client, http) = makeUserAuthClient()
            await http.addMockResponse(
                data: makeAlbumJSON(
                    id: "album123",
                    name: "Test Album",
                    artistName: "Test Artist",
                    totalTracks: 10,
                    popularity: 50
                ),
                statusCode: 200
            )

            let album = try await awaitFirstValue(
                client.albums.getPublisher("album123", market: "US")
            )
            #expect(album.id == "album123")
        }

        @Test("makePublisher with three parameters")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherWithThreeParameters() async throws {
            let (client, http) = makeUserAuthClient()
            await http.addMockResponse(
                data: makeJSONData(#"{"tracks": []}"#),
                statusCode: 200
            )

            let tracks = try await awaitFirstValue(
                client.artists.topTracksPublisher(for: "artist123", market: "GB")
            )
            #expect(tracks.isEmpty)
        }

        @Test("makePublisher with four parameters")
        @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
        func makePublisherWithFourParameters() async throws {
            let (client, http) = makeUserAuthClient()
            await http.addMockResponse(
                data: makeJSONData(#"{"tracks": {"items": [], "total": 0, "limit": 10, "offset": 0, "href": "https://api.spotify.com/v1/search", "next": null, "previous": null}}"#),
                statusCode: 200
            )

            let results = try await awaitFirstValue(
                client.search.executePublisher(
                    query: "test",
                    types: [.track],
                    market: "US",
                    limit: 10
                )
            )
            #expect(results.tracks?.items.isEmpty == true)
        }
    }
#endif

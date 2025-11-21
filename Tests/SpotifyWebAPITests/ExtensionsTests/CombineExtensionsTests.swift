import Foundation
import Testing

@testable import SpotifyWebAPI

#if canImport(Combine)
import Combine

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@Suite
struct CombineExtensionsTests {
    
    @Test
    @MainActor
    func albumsService_getPublisher_success() async throws {
        let (client, http) = makeUserAuthClient()
        let albumData = try TestDataLoader.load("album_full")
        await http.addMockResponse(data: albumData, statusCode: 200)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        client.albums.getPublisher("test_album_id")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Issue.record("Unexpected error: \(error)")
                    }
                },
                receiveValue: { album in
                    #expect(album.id == "4aawyAB9vmqN3uQ7FjRGTy")
                    #expect(album.name == "Global Warming")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        await expectation.fulfillment
        
        let requests = await http.requests
        #expect(requests.count == 1)
        #expect(requests.first?.url?.path() == "/albums/test_album_id")
    }
    
    @Test
    @MainActor
    func albumsService_getPublisher_failure() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 404)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        client.albums.getPublisher("nonexistent_id")
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    Issue.record("Expected failure but got success")
                }
            )
            .store(in: &cancellables)
        
        await expectation.fulfillment
    }
    
    @Test
    @MainActor
    func searchService_executePublisher_success() async throws {
        let (client, http) = makeUserAuthClient()
        let searchData = try TestDataLoader.load("search_results")
        await http.addMockResponse(data: searchData, statusCode: 200)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        client.search.executePublisher(
            query: "Queen",
            types: [.track, .artist]
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Issue.record("Unexpected error: \(error)")
                }
            },
            receiveValue: { results in
                #expect(results.tracks != nil)
                #expect(results.artists != nil)
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        await expectation.fulfillment
        
        let requests = await http.requests
        #expect(requests.count == 1)
        #expect(requests.first?.url?.path() == "/search")
        #expect(requests.first?.url?.query()?.contains("q=Queen") == true)
    }
    
    @Test
    @MainActor
    func playlistsService_myPlaylistsPublisher_success() async throws {
        let (client, http) = makeUserAuthClient()
        let playlistsData = try TestDataLoader.load("playlists_user")
        await http.addMockResponse(data: playlistsData, statusCode: 200)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        client.playlists.myPlaylistsPublisher(limit: 10)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Issue.record("Unexpected error: \(error)")
                    }
                },
                receiveValue: { page in
                    #expect(page.items.count > 0)
                    #expect(page.limit == 20)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        await expectation.fulfillment
    }
    
    @Test
    @MainActor
    func usersService_mePublisher_success() async throws {
        let (client, http) = makeUserAuthClient()
        let profileData = try TestDataLoader.load("current_user_profile")
        await http.addMockResponse(data: profileData, statusCode: 200)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        client.users.mePublisher()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Issue.record("Unexpected error: \(error)")
                    }
                },
                receiveValue: { profile in
                    #expect(profile.id == "smedjan")
                    #expect(profile.displayName == "JM Wizzler")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        await expectation.fulfillment
    }
    
    @Test
    @MainActor
    func albumsService_savePublisher_success() async throws {
        let (client, http) = makeUserAuthClient()
        await http.addMockResponse(statusCode: 200)
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        let albumIDs: Set<String> = ["album1", "album2"]
        
        client.albums.savePublisher(albumIDs)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Issue.record("Unexpected error: \(error)")
                    } else {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    // Void return type
                }
            )
            .store(in: &cancellables)
        
        await expectation.fulfillment
        
        let requests = await http.requests
        #expect(requests.count == 1)
        #expect(requests.first?.url?.path() == "/me/albums")
        #expect(requests.first?.httpMethod == "PUT")
    }
    
    @Test
    @MainActor
    func publisher_cancellation_works() async throws {
        let (client, http) = makeUserAuthClient()
        
        // Don't add any mock responses to simulate a hanging request
        
        var cancellables = Set<AnyCancellable>()
        let expectation = AsyncExpectation()
        
        let cancellable = client.albums.getPublisher("test")
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    Issue.record("Should not receive value after cancellation")
                }
            )
        
        // Cancel immediately
        cancellable.cancel()
        
        // Give it a moment to process cancellation
        try await Task.sleep(for: .milliseconds(100))
        
        await expectation.fulfillment
    }
}

// MARK: - Test Helpers

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor AsyncExpectation {
    private var isFulfilled = false
    
    func fulfill() {
        isFulfilled = true
    }
    
    var fulfillment: Void {
        get async {
            while !isFulfilled {
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
    }
}

#endif
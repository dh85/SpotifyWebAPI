import Foundation
import Testing
@testable import SpotifyKit

struct RequestDeduplicationTests {
    
    @Test
    func requestDeduplicationBasic() async throws {
        // Create a simple test to verify deduplication works
        let client = SpotifyClient.pkce(
            clientID: "test-client-id",
            redirectURI: URL(string: "test://callback")!,
            scopes: [.userReadPrivate]
        )
        
        // Test that the ongoingRequests dictionary exists and is empty initially
        let mirror = Mirror(reflecting: client)
        let ongoingRequestsProperty = mirror.children.first { $0.label == "ongoingRequests" }
        #expect(ongoingRequestsProperty != nil, "ongoingRequests property should exist")
    }
    
    @Test
    func concurrentIdenticalRequestsAreDeduplicated() async throws {
        let httpClient = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        
        let client: SpotifyClient<UserAuthCapability> = SpotifyClient(
            backend: auth,
            httpClient: httpClient
        )
        
        // Use the actual album JSON structure from the mock files
        let albumData = """
        {
            "album_type": "album",
            "total_tracks": 10,
            "available_markets": ["US", "CA"],
            "external_urls": {"spotify": "https://open.spotify.com/album/test-album"},
            "href": "https://api.spotify.com/v1/albums/test-album",
            "id": "test-album",
            "images": [],
            "name": "Test Album",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "album",
            "uri": "spotify:album:test-album",
            "artists": [{
                "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"},
                "href": "https://api.spotify.com/v1/artists/artist1",
                "id": "artist1",
                "name": "Test Artist",
                "type": "artist",
                "uri": "spotify:artist:artist1"
            }],
            "tracks": {
                "href": "https://api.spotify.com/v1/albums/test-album/tracks",
                "limit": 50,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": 10,
                "items": []
            },
            "copyrights": [],
            "external_ids": {},
            "genres": [],
            "label": "Test Label",
            "popularity": 50
        }
        """.data(using: .utf8)!
        
        await httpClient.addMockResponse(data: albumData, statusCode: 200)
        
        // Make 3 concurrent identical requests
        async let album1 = client.albums.get("test-album")
        async let album2 = client.albums.get("test-album")
        async let album3 = client.albums.get("test-album")
        
        let results = try await [album1, album2, album3]
        
        // All requests should return the same album
        #expect(results.count == 3)
        for album in results {
            #expect(album.id == "test-album")
            #expect(album.name == "Test Album")
        }
        
        // Only one HTTP request should have been made due to deduplication
        #expect(await httpClient.requests.count == 1)
    }
    
    @Test
    func differentRequestsAreNotDeduplicated() async throws {
        let httpClient = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        
        let client: SpotifyClient<UserAuthCapability> = SpotifyClient(
            backend: auth,
            httpClient: httpClient
        )
        
        // Setup mock responses for different albums
        let album1Data = """
        {
            "album_type": "album",
            "total_tracks": 10,
            "available_markets": ["US", "CA"],
            "external_urls": {"spotify": "https://open.spotify.com/album/album-1"},
            "href": "https://api.spotify.com/v1/albums/album-1",
            "id": "album-1",
            "images": [],
            "name": "Album 1",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "album",
            "uri": "spotify:album:album-1",
            "artists": [{
                "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"},
                "href": "https://api.spotify.com/v1/artists/artist1",
                "id": "artist1",
                "name": "Artist 1",
                "type": "artist",
                "uri": "spotify:artist:artist1"
            }],
            "tracks": {
                "href": "https://api.spotify.com/v1/albums/album-1/tracks",
                "limit": 50,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": 10,
                "items": []
            },
            "copyrights": [],
            "external_ids": {},
            "genres": [],
            "label": "Test Label",
            "popularity": 50
        }
        """.data(using: .utf8)!
        
        let album2Data = """
        {
            "album_type": "album",
            "total_tracks": 12,
            "available_markets": ["US", "CA"],
            "external_urls": {"spotify": "https://open.spotify.com/album/album-2"},
            "href": "https://api.spotify.com/v1/albums/album-2",
            "id": "album-2",
            "images": [],
            "name": "Album 2",
            "release_date": "2023-02-01",
            "release_date_precision": "day",
            "type": "album",
            "uri": "spotify:album:album-2",
            "artists": [{
                "external_urls": {"spotify": "https://open.spotify.com/artist/artist2"},
                "href": "https://api.spotify.com/v1/artists/artist2",
                "id": "artist2",
                "name": "Artist 2",
                "type": "artist",
                "uri": "spotify:artist:artist2"
            }],
            "tracks": {
                "href": "https://api.spotify.com/v1/albums/album-2/tracks",
                "limit": 50,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": 12,
                "items": []
            },
            "copyrights": [],
            "external_ids": {},
            "genres": [],
            "label": "Test Label",
            "popularity": 45
        }
        """.data(using: .utf8)!
        
        await httpClient.addMockResponse(data: album1Data, statusCode: 200)
        await httpClient.addMockResponse(data: album2Data, statusCode: 200)
        
        // Make concurrent requests for different albums
        async let album1 = client.albums.get("album-1")
        async let album2 = client.albums.get("album-2")
        
        let results = try await [album1, album2]
        
        // Both requests should complete with different results
        #expect(results.count == 2)
        let albumIDs = Set(results.map { $0.id })
        #expect(albumIDs.contains("album-1"))
        #expect(albumIDs.contains("album-2"))
        
        // Two HTTP requests should have been made (different requests)
        #expect(await httpClient.requests.count == 2)
    }
    
    @Test
    func sequentialIdenticalRequestsAreNotDeduplicated() async throws {
        let httpClient = MockHTTPClient()
        let auth = MockTokenAuthenticator(token: .mockValid)
        
        let client: SpotifyClient<UserAuthCapability> = SpotifyClient(
            backend: auth,
            httpClient: httpClient
        )
        
        // Setup mock responses
        let albumData = """
        {
            "album_type": "album",
            "total_tracks": 10,
            "available_markets": ["US", "CA"],
            "external_urls": {"spotify": "https://open.spotify.com/album/test-album"},
            "href": "https://api.spotify.com/v1/albums/test-album",
            "id": "test-album",
            "images": [],
            "name": "Test Album",
            "release_date": "2023-01-01",
            "release_date_precision": "day",
            "type": "album",
            "uri": "spotify:album:test-album",
            "artists": [{
                "external_urls": {"spotify": "https://open.spotify.com/artist/artist1"},
                "href": "https://api.spotify.com/v1/artists/artist1",
                "id": "artist1",
                "name": "Test Artist",
                "type": "artist",
                "uri": "spotify:artist:artist1"
            }],
            "tracks": {
                "href": "https://api.spotify.com/v1/albums/test-album/tracks",
                "limit": 50,
                "next": null,
                "offset": 0,
                "previous": null,
                "total": 10,
                "items": []
            },
            "copyrights": [],
            "external_ids": {},
            "genres": [],
            "label": "Test Label",
            "popularity": 50
        }
        """.data(using: .utf8)!
        
        await httpClient.addMockResponse(data: albumData, statusCode: 200)
        await httpClient.addMockResponse(data: albumData, statusCode: 200)
        
        // Make sequential identical requests
        let album1 = try await client.albums.get("test-album")
        let album2 = try await client.albums.get("test-album")
        
        #expect(album1.id == "test-album")
        #expect(album2.id == "test-album")
        
        // Two HTTP requests should have been made (sequential, not concurrent)
        #expect(await httpClient.requests.count == 2)
    }
}
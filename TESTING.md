# Testing with SpotifyWebAPI

This guide shows how to test your code that uses SpotifyWebAPI.

## MockSpotifyClient

Use `MockSpotifyClient` to test your code without making real API calls.

### Basic Usage

```swift
import Testing
import SpotifyWebAPI

@Test func testMyViewModel() async throws {
    // Create mock client
    let mock = MockSpotifyClient()
    
    // Set up mock data
    mock.mockProfile = CurrentUserProfile(
        id: "test123",
        displayName: "Test User",
        // ... other fields
    )
    
    // Use mock in your code
    let viewModel = MyViewModel(client: mock)
    await viewModel.loadProfile()
    
    // Verify behavior
    #expect(viewModel.userName == "Test User")
    #expect(mock.getUsersCalled == true)
}
```

### Mock Data Properties

Set these properties to return mock data:

```swift
mock.mockProfile = CurrentUserProfile(...)
mock.mockAlbum = Album(...)
mock.mockTrack = Track(...)
mock.mockPlaylist = Playlist(...)
mock.mockPlaylists = [SimplifiedPlaylist(...)]
mock.mockArtist = Artist(...)
mock.mockPlaybackState = PlaybackState(...)
```

### Error Testing

Test error handling by setting `mockError`:

```swift
@Test func testErrorHandling() async throws {
    let mock = MockSpotifyClient()
    mock.mockError = SpotifyAuthError.httpError(statusCode: 404, body: "Not Found")
    
    let viewModel = MyViewModel(client: mock)
    await viewModel.loadProfile()
    
    #expect(viewModel.errorMessage == "Not Found")
}
```

### Call Tracking

Verify methods were called:

```swift
@Test func testPlaybackControl() async throws {
    let mock = MockSpotifyClient()
    
    let controller = PlaybackController(client: mock)
    await controller.pause()
    
    #expect(mock.pauseCalled == true)
    #expect(mock.playCalled == false)
}
```

### Reset Between Tests

Reset mock state between tests:

```swift
@Test func testMultipleScenarios() async throws {
    let mock = MockSpotifyClient()
    
    // First scenario
    mock.mockProfile = profile1
    // ... test code ...
    
    // Reset for next scenario
    mock.reset()
    
    // Second scenario
    mock.mockProfile = profile2
    // ... test code ...
}
```

## Example: Testing a ViewModel

```swift
// Your ViewModel
class MusicViewModel {
    private let client: MockSpotifyClient
    var userName: String?
    var playlists: [SimplifiedPlaylist] = []
    var errorMessage: String?
    
    init(client: MockSpotifyClient) {
        self.client = client
    }
    
    func loadUserData() async {
        do {
            let profile = try await client.me()
            userName = profile.displayName
            
            playlists = try await client.myPlaylists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Your Tests
@Suite struct MusicViewModelTests {
    
    @Test func loadsUserData() async throws {
        let mock = MockSpotifyClient()
        mock.mockProfile = CurrentUserProfile(id: "test", displayName: "Test User", ...)
        mock.mockPlaylists = [
            SimplifiedPlaylist(id: "p1", name: "My Playlist", ...)
        ]
        
        let viewModel = MusicViewModel(client: mock)
        await viewModel.loadUserData()
        
        #expect(viewModel.userName == "Test User")
        #expect(viewModel.playlists.count == 1)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func handlesErrors() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.unexpectedResponse
        
        let viewModel = MusicViewModel(client: mock)
        await viewModel.loadUserData()
        
        #expect(viewModel.userName == nil)
        #expect(viewModel.errorMessage != nil)
    }
}
```

## Best Practices

1. **Use mock data from test fixtures** - Load real JSON responses for realistic tests
2. **Test error paths** - Use `mockError` to test error handling
3. **Verify method calls** - Check that your code calls the right methods
4. **Reset between tests** - Call `mock.reset()` to avoid test pollution
5. **Keep mocks simple** - Only set the data you need for each test

## Integration Testing

For integration tests with real API calls, use a test Spotify account:

```swift
@Test func integrationTest() async throws {
    let client = UserSpotifyClient.pkce(
        clientID: ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"]!,
        redirectURI: URL(string: "test://callback")!,
        scopes: [.userReadEmail]
    )
    
    // Perform real API calls
    let profile = try await client.users.me()
    #expect(profile.id != nil)
}
```

**Note**: Integration tests require valid credentials and should be run separately from unit tests.

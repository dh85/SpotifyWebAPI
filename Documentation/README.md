# SpotifyWebAPI

A comprehensive Swift library for the Spotify Web API with full async/await support, authentication flows, and testing utilities.

## Features

- ✅ **Complete Spotify Web API Coverage** - Albums, Artists, Tracks, Playlists, Player, Search, and more
- ✅ **Multiple Authentication Flows** - Authorization Code, PKCE, Client Credentials
- ✅ **Async/await Support** - Modern Swift concurrency
- ✅ **Request Deduplication** - Automatic duplicate request handling
- ✅ **Rate Limiting** - Built-in retry logic with exponential backoff
- ✅ **Network Recovery** - Automatic retry on network failures
- ✅ **Testing Support** - MockSpotifyClient for unit tests
- ✅ **Debug Tooling** - Comprehensive logging and performance metrics
- ✅ **Type Safety** - Strongly typed models for all API responses
- ✅ **Pagination Support** - Easy handling of paginated results

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SpotifyWebAPI.git", from: "1.0.0")
]
```

## Quick Start

### 1. Authentication

#### Authorization Code Flow (Recommended for iOS/macOS apps)

```swift
import SpotifyWebAPI

let authenticator = SpotifyAuthorizationCodeAuthenticator(
    clientId: "your-client-id",
    clientSecret: "your-client-secret",
    redirectURI: URL(string: "your-app://callback")!
)

let client = SpotifyClient(authenticator: authenticator)

// Generate authorization URL
let authURL = authenticator.makeAuthorizationURL(
    scopes: [.userReadPrivate, .userReadEmail, .playlistReadPrivate],
    state: "random-state-string"
)

// Handle callback after user authorization
try await authenticator.handleCallback(url: callbackURL, state: "random-state-string")
```

#### PKCE Flow (Recommended for mobile apps)

```swift
let authenticator = SpotifyPKCEAuthenticator(
    clientId: "your-client-id",
    redirectURI: URL(string: "your-app://callback")!
)

let client = SpotifyClient(authenticator: authenticator)

// Generate PKCE pair and authorization URL
let pkcePair = try authenticator.generatePKCE()
let authURL = authenticator.makeAuthorizationURL(
    scopes: [.userReadPrivate, .userReadEmail],
    codeChallenge: pkcePair.codeChallenge,
    state: "random-state-string"
)

// Handle callback
try await authenticator.handleCallback(
    url: callbackURL,
    codeVerifier: pkcePair.codeVerifier,
    state: "random-state-string"
)
```

#### Client Credentials Flow (For server-side apps)

```swift
let authenticator = SpotifyClientCredentialsAuthenticator(
    clientId: "your-client-id",
    clientSecret: "your-client-secret"
)

let client = SpotifyClient(authenticator: authenticator)
```

### 2. Basic Usage

```swift
// Get current user profile
let profile = try await client.users.me()
print("Hello, \(profile.displayName ?? "User")!")

// Search for tracks
let searchResults = try await client.search.execute(
    query: "Bohemian Rhapsody",
    types: [.track],
    limit: 10
)

// Get user's playlists
let playlists = try await client.playlists.my()
```

## Core Features

### User Profile

```swift
// Get current user profile
let profile = try await client.users.me()
print("User ID: \(profile.id)")
print("Display Name: \(profile.displayName ?? "N/A")")
print("Email: \(profile.email ?? "N/A")")
print("Country: \(profile.country ?? "N/A")")
print("Followers: \(profile.followers.total)")

// Get public user profile
let publicProfile = try await client.users.get("spotify")
```

### Albums

```swift
// Get album by ID
let album = try await client.albums.get("4aawyAB9vmqN3uQ7FjRGTy")
print("Album: \(album.name) by \(album.artists.map(\.name).joined(separator: ", "))")

// Get multiple albums
let albums = try await client.albums.several([
    "4aawyAB9vmqN3uQ7FjRGTy",
    "1DFixLWuPkv3KT3TnV35m3"
])

// Get album tracks
let tracks = try await client.albums.tracks("4aawyAB9vmqN3uQ7FjRGTy")

// Save/remove albums from library
try await client.albums.save(["4aawyAB9vmqN3uQ7FjRGTy"])
try await client.albums.remove(["4aawyAB9vmqN3uQ7FjRGTy"])

// Check if albums are saved
let savedStatus = try await client.albums.checkSaved(["4aawyAB9vmqN3uQ7FjRGTy"])

// Get saved albums
let savedAlbums = try await client.albums.saved(limit: 20)
```

### Artists

```swift
// Get artist by ID
let artist = try await client.getArtist("0TnOYISbd1XYRBk9myaseg")
print("Artist: \(artist.name)")
print("Genres: \(artist.genres.joined(separator: ", "))")
print("Popularity: \(artist.popularity)")

// Get multiple artists
let artists = try await client.getArtists([
    "0TnOYISbd1XYRBk9myaseg",
    "1vCWHaC5f2uS3yhpwWbIA6"
])

// Get artist's albums
let artistAlbums = try await client.getArtistAlbums(
    "0TnOYISbd1XYRBk9myaseg",
    includeGroups: [.album, .single],
    market: "US",
    limit: 20
)

// Get artist's top tracks
let topTracks = try await client.getArtistTopTracks(
    "0TnOYISbd1XYRBk9myaseg",
    market: "US"
)

// Get related artists
let relatedArtists = try await client.getRelatedArtists("0TnOYISbd1XYRBk9myaseg")
```

### Tracks

```swift
// Get track by ID
let track = try await client.getTrack("11dFghVXANMlKmJXsNCbNl")
print("Track: \(track.name) by \(track.artists.map(\.name).joined(separator: ", "))")
print("Duration: \(track.durationMs / 1000) seconds")

// Get multiple tracks
let tracks = try await client.getTracks([
    "11dFghVXANMlKmJXsNCbNl",
    "6rqhFgbbKwnb9MLmUQDhG6"
])

// Save/remove tracks from library
try await client.saveTracks(["11dFghVXANMlKmJXsNCbNl"])
try await client.removeTracks(["11dFghVXANMlKmJXsNCbNl"])

// Check if tracks are saved
let savedStatus = try await client.checkSavedTracks(["11dFghVXANMlKmJXsNCbNl"])

// Get saved tracks
let savedTracks = try await client.savedTracks(limit: 20)

// Get audio features
let audioFeatures = try await client.getAudioFeatures("11dFghVXANMlKmJXsNCbNl")
print("Danceability: \(audioFeatures.danceability)")
print("Energy: \(audioFeatures.energy)")
print("Valence: \(audioFeatures.valence)")

// Get audio analysis
let audioAnalysis = try await client.getAudioAnalysis("11dFghVXANMlKmJXsNCbNl")
```

### Playlists

```swift
// Get playlist by ID
let playlist = try await client.getPlaylist("37i9dQZF1DXcBWIGoYBM5M")
print("Playlist: \(playlist.name)")
print("Description: \(playlist.description ?? "N/A")")
print("Tracks: \(playlist.tracks.total)")

// Get playlist tracks
let playlistTracks = try await client.getPlaylistTracks("37i9dQZF1DXcBWIGoYBM5M")

// Get user's playlists
let myPlaylists = try await client.myPlaylists()

// Get another user's playlists
let userPlaylists = try await client.getUserPlaylists("spotify", limit: 20)

// Create playlist
let newPlaylist = try await client.createPlaylist(
    name: "My Awesome Playlist",
    description: "Created with SpotifyWebAPI",
    isPublic: false
)

// Add tracks to playlist
try await client.addTracksToPlaylist(
    newPlaylist.id,
    uris: [
        "spotify:track:11dFghVXANMlKmJXsNCbNl",
        "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
    ]
)

// Remove tracks from playlist
try await client.removeTracksFromPlaylist(
    newPlaylist.id,
    uris: ["spotify:track:11dFghVXANMlKmJXsNCbNl"]
)

// Reorder playlist tracks
try await client.reorderPlaylistTracks(
    newPlaylist.id,
    rangeStart: 0,
    insertBefore: 2,
    rangeLength: 1
)

// Change playlist details
try await client.changePlaylistDetails(
    newPlaylist.id,
    name: "Updated Playlist Name",
    description: "Updated description"
)

// Follow/unfollow playlist
try await client.followPlaylist("37i9dQZF1DXcBWIGoYBM5M")
try await client.unfollowPlaylist("37i9dQZF1DXcBWIGoYBM5M")

// Check if following playlist
let isFollowing = try await client.checkFollowingPlaylist(
    "37i9dQZF1DXcBWIGoYBM5M",
    userIds: ["your-user-id"]
)
```

### Player Control

```swift
// Get current playback state
if let playbackState = try await client.playbackState() {
    print("Currently playing: \(playbackState.item?.name ?? "Nothing")")
    print("Is playing: \(playbackState.isPlaying)")
    print("Progress: \(playbackState.progressMs ?? 0)ms")
    print("Device: \(playbackState.device?.name ?? "Unknown")")
}

// Get available devices
let devices = try await client.getDevices()
for device in devices {
    print("Device: \(device.name) (\(device.type))")
}

// Transfer playback to device
try await client.transferPlayback(to: "device-id", play: true)

// Play/pause
try await client.play()
try await client.pause()

// Skip tracks
try await client.skipToNext()
try await client.skipToPrevious()

// Seek to position
try await client.seek(to: 30000) // 30 seconds

// Set volume
try await client.setVolume(50) // 50%

// Set repeat mode
try await client.setRepeatMode(.track)

// Set shuffle
try await client.setShuffle(true)

// Play specific tracks
try await client.play(uris: [
    "spotify:track:11dFghVXANMlKmJXsNCbNl",
    "spotify:track:6rqhFgbbKwnb9MLmUQDhG6"
])

// Play album
try await client.play(contextURI: "spotify:album:4aawyAB9vmqN3uQ7FjRGTy")

// Add to queue
try await client.addToQueue("spotify:track:11dFghVXANMlKmJXsNCbNl")

// Get queue
let queue = try await client.getQueue()
print("Currently playing: \(queue.currentlyPlaying?.name ?? "Nothing")")
print("Queue length: \(queue.queue.count)")

// Get recently played tracks
let recentlyPlayed = try await client.recentlyPlayed(limit: 20)
```

### Search

```swift
// Search for tracks
let trackResults = try await client.search(
    query: "Bohemian Rhapsody",
    types: [.track],
    market: "US",
    limit: 10
)

// Search for multiple types
let searchResults = try await client.search(
    query: "Queen",
    types: [.artist, .album, .track],
    limit: 5
)

print("Artists found: \(searchResults.artists?.items.count ?? 0)")
print("Albums found: \(searchResults.albums?.items.count ?? 0)")
print("Tracks found: \(searchResults.tracks?.items.count ?? 0)")

// Advanced search with filters
let filteredResults = try await client.search(
    query: "year:2020 genre:rock",
    types: [.track],
    limit: 20
)
```

### Browse

```swift
// Get new releases
let newReleases = try await client.newReleases(country: "US", limit: 20)

// Get featured playlists
let featuredPlaylists = try await client.featuredPlaylists(
    country: "US",
    limit: 10
)

// Get categories
let categories = try await client.getCategories(country: "US", limit: 20)

// Get category playlists
let categoryPlaylists = try await client.getCategoryPlaylists(
    "pop",
    country: "US",
    limit: 10
)

// Get recommendations
let recommendations = try await client.getRecommendations(
    seedArtists: ["0TnOYISbd1XYRBk9myaseg"],
    seedTracks: ["11dFghVXANMlKmJXsNCbNl"],
    limit: 20,
    targetDanceability: 0.8,
    targetEnergy: 0.7
)
```

### User Library & Following

```swift
// Follow/unfollow artists
try await client.followArtists(["0TnOYISbd1XYRBk9myaseg"])
try await client.unfollowArtists(["0TnOYISbd1XYRBk9myaseg"])

// Follow/unfollow users
try await client.followUsers(["spotify"])
try await client.unfollowUsers(["spotify"])

// Check if following
let followingArtists = try await client.checkFollowingArtists(["0TnOYISbd1XYRBk9myaseg"])
let followingUsers = try await client.checkFollowingUsers(["spotify"])

// Get followed artists
let followedArtists = try await client.followedArtists(limit: 20)

// Get user's top items
let topArtists = try await client.topArtists(
    timeRange: .mediumTerm,
    limit: 20
)

let topTracks = try await client.topTracks(
    timeRange: .shortTerm,
    limit: 20
)
```

## Advanced Features

### Pagination

```swift
// Manual pagination
var allPlaylists: [SimplifiedPlaylist] = []
var nextURL: URL? = nil

repeat {
    let page = try await client.myPlaylists(offset: allPlaylists.count, limit: 50)
    allPlaylists.append(contentsOf: page.items)
    nextURL = page.next
} while nextURL != nil

// Using pagination helpers
let allItems = try await client.collectAllPages { offset in
    try await client.myPlaylists(offset: offset, limit: 50)
}

// Streaming pagination
for try await playlist in client.streamPages { offset in
    try await client.myPlaylists(offset: offset, limit: 50)
} {
    print("Playlist: \(playlist.name)")
}
```

### Error Handling

```swift
do {
    let profile = try await client.me()
    print("User: \(profile.displayName ?? "Unknown")")
} catch SpotifyAuthError.tokenExpired {
    // Handle expired token
    print("Token expired, need to refresh")
} catch SpotifyAuthError.invalidCredentials {
    // Handle invalid credentials
    print("Invalid credentials")
} catch let error as SpotifyAPIError {
    // Handle API errors
    print("API Error: \(error.localizedDescription)")
    if let statusCode = error.statusCode {
        print("Status Code: \(statusCode)")
    }
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

### Configuration

```swift
// Custom configuration
let config = SpotifyClientConfiguration(
    maxRateLimitRetries: 5,
    rateLimitRetryDelay: 2.0,
    requestTimeout: 30.0,
    customHeaders: ["User-Agent": "MyApp/1.0"],
    debugConfiguration: .init(
        enableRequestLogging: true,
        enableResponseLogging: true,
        enablePerformanceMetrics: true,
        logLevel: .info
    )
)

let client = SpotifyClient(
    authenticator: authenticator,
    configuration: config
)
```

### Token Storage

```swift
// File-based token storage
let tokenStore = FileTokenStore(directory: .documentsDirectory)
let authenticator = SpotifyAuthorizationCodeAuthenticator(
    clientId: "your-client-id",
    clientSecret: "your-client-secret",
    redirectURI: URL(string: "your-app://callback")!,
    tokenStore: tokenStore
)

// Custom token storage
class CustomTokenStore: TokenStore {
    func load() async throws -> SpotifyTokens? {
        // Load tokens from your preferred storage
        return nil
    }
    
    func save(_ tokens: SpotifyTokens) async throws {
        // Save tokens to your preferred storage
    }
    
    func clear() async throws {
        // Clear stored tokens
    }
}
```

## Testing

### MockSpotifyClient

```swift
import XCTest
@testable import SpotifyWebAPI

class MyViewModelTests: XCTestCase {
    func testLoadProfile() async throws {
        // Setup mock
        let mock = MockSpotifyClient()
        mock.mockProfile = CurrentUserProfile(
            id: "test-user",
            displayName: "Test User",
            email: "test@example.com",
            country: "US",
            product: "premium",
            href: URL(string: "https://api.spotify.com/v1/users/test-user")!,
            externalUrls: SpotifyExternalUrls(spotify: nil),
            images: [],
            followers: SpotifyFollowers(href: nil, total: 100),
            explicitContent: nil,
            type: .user,
            uri: "spotify:user:test-user"
        )
        
        // Test your code
        let viewModel = MyViewModel(client: mock)
        await viewModel.loadProfile()
        
        // Verify
        XCTAssertEqual(viewModel.userName, "Test User")
        XCTAssertTrue(mock.getUsersCalled)
    }
    
    func testErrorHandling() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.tokenExpired
        
        let viewModel = MyViewModel(client: mock)
        
        do {
            await viewModel.loadProfile()
            XCTFail("Should have thrown error")
        } catch SpotifyAuthError.tokenExpired {
            // Expected error
        }
        
        XCTAssertTrue(mock.getUsersCalled)
    }
}
```

### Testing Utilities

```swift
// Mock all methods
let mock = MockSpotifyClient()

// Set up mock data
mock.mockProfile = testProfile
mock.mockAlbum = testAlbum
mock.mockTrack = testTrack
mock.mockPlaylist = testPlaylist
mock.mockPlaylists = [testPlaylist1, testPlaylist2]
mock.mockPlaybackState = testPlaybackState

// Test error scenarios
mock.mockError = SpotifyAuthError.tokenExpired

// Verify method calls
XCTAssertTrue(mock.getUsersCalled)
XCTAssertTrue(mock.getAlbumCalled)
XCTAssertTrue(mock.pauseCalled)

// Reset for next test
mock.reset()
```

## Best Practices

### 1. Token Management

```swift
// Always handle token expiration
class SpotifyService {
    private let client: SpotifyClient
    
    init(client: SpotifyClient) {
        self.client = client
    }
    
    func getCurrentUser() async throws -> CurrentUserProfile {
        do {
            return try await client.me()
        } catch SpotifyAuthError.tokenExpired {
            // Refresh token automatically handled by authenticator
            return try await client.me()
        }
    }
}
```

### 2. Rate Limiting

```swift
// The library handles rate limiting automatically, but you can configure it
let config = SpotifyClientConfiguration(
    maxRateLimitRetries: 3,
    rateLimitRetryDelay: 1.0
)
```

### 3. Batch Operations

```swift
// Use batch operations for better performance
let albumIds = ["id1", "id2", "id3", "id4", "id5"]

// Instead of multiple single requests
// let albums = try await albumIds.asyncMap { try await client.getAlbum($0) }

// Use batch request
let albums = try await client.getAlbums(albumIds)
```

### 4. Memory Management

```swift
// Use streaming for large datasets
for try await track in client.streamPages { offset in
    try await client.savedTracks(offset: offset, limit: 50)
} {
    // Process track without loading all into memory
    processTrack(track)
}
```

## Error Types

- `SpotifyAuthError` - Authentication related errors
- `SpotifyAPIError` - API response errors
- `NetworkError` - Network connectivity issues
- `MockError` - Testing mock errors

## Scopes

Common Spotify scopes you might need:

```swift
let scopes: Set<SpotifyScope> = [
    .userReadPrivate,           // Read user profile
    .userReadEmail,             // Read user email
    .playlistReadPrivate,       // Read private playlists
    .playlistModifyPublic,      // Modify public playlists
    .playlistModifyPrivate,     // Modify private playlists
    .userLibraryRead,           // Read saved tracks/albums
    .userLibraryModify,         // Modify saved tracks/albums
    .userReadPlaybackState,     // Read playback state
    .userModifyPlaybackState,   // Control playback
    .userReadRecentlyPlayed,    // Read recently played
    .userTopRead,               // Read top artists/tracks
    .userFollowRead,            // Read following
    .userFollowModify           // Modify following
]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
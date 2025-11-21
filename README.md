# SpotifyWebAPI

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-blue.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-520%20passing-brightgreen.svg)](#testing)

A comprehensive, type-safe Swift library for the Spotify Web API with full async/await support, multiple authentication flows, and extensive testing utilities.

## ✨ Features

- 🎵 **Complete Spotify Web API Coverage** - Albums, Artists, Tracks, Playlists, Player, Search, Browse, and more
- 🔐 **Multiple Authentication Flows** - Authorization Code, PKCE, Client Credentials
- ⚡ **Modern Swift Concurrency** - Full async/await support with structured concurrency
- 🔄 **Request Deduplication** - Automatic duplicate request handling for better performance
- 🚦 **Smart Rate Limiting** - Built-in retry logic with exponential backoff
- 🛡️ **Network Recovery** - Automatic retry on network failures with configurable policies
- 🧪 **Testing Support** - Comprehensive MockSpotifyClient for unit testing
- 📊 **Debug Tooling** - Detailed logging, performance metrics, and request/response tracking
- 🎯 **Type Safety** - Strongly typed models for all API responses with full Codable support
- 📄 **Pagination Helpers** - Easy handling of paginated results with streaming support
- 🔧 **Highly Configurable** - Customizable timeouts, headers, retry policies, and more

## 📦 Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SpotifyWebAPI.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/your-org/SpotifyWebAPI.git`

## 🚀 Quick Start

### 1. Set up Authentication

Choose the authentication flow that best fits your app:

#### For iOS/macOS Apps (Authorization Code + PKCE)

```swift
import SpotifyWebAPI

let authenticator = SpotifyPKCEAuthenticator(
    clientId: "your-client-id",
    redirectURI: URL(string: "your-app://callback")!,
    scopes: [.userReadPrivate, .userReadEmail, .playlistReadPrivate]
)

let client = SpotifyClient(authenticator: authenticator)

// Generate authorization URL
let pkcePair = try authenticator.generatePKCE()
let authURL = authenticator.makeAuthorizationURL(
    scopes: [.userReadPrivate, .userReadEmail],
    codeChallenge: pkcePair.codeChallenge,
    state: "random-state-string"
)

// Handle callback after user authorization
try await authenticator.handleCallback(
    url: callbackURL,
    codeVerifier: pkcePair.codeVerifier,
    state: "random-state-string"
)
```

#### For Server-Side Apps (Client Credentials)

```swift
let authenticator = SpotifyClientCredentialsAuthenticator(
    clientId: "your-client-id",
    clientSecret: "your-client-secret"
)

let client = SpotifyClient(authenticator: authenticator)
```

### 2. Start Making API Calls

```swift
// Get current user profile
let profile = try await client.users.me()
print("Hello, \(profile.displayName ?? "User")!")

// Search for music
let searchResults = try await client.search.execute(
    query: "Bohemian Rhapsody",
    types: [.track],
    limit: 10
)

// Control playback
try await client.player.resume()
try await client.player.pause()
try await client.player.skipToNext()

// Get user's playlists
let playlists = try await client.playlists.myPlaylists()
for playlist in playlists.items {
    print("Playlist: \(playlist.name) (\(playlist.tracks.total) tracks)")
}
```

## 📚 Documentation

- **[Complete Documentation](Documentation/README.md)** - Comprehensive guide with examples
- **[API Reference](Documentation/API_Reference.md)** - Detailed API documentation
- **[Examples](Documentation/Examples.md)** - Real-world usage examples

## 🎯 Core Features

### User Profile & Library

```swift
// Get current user
let user = try await client.users.me()

// Manage saved tracks
try await client.tracks.save(["track-id-1", "track-id-2"])
let savedTracks = try await client.tracks.saved()

// Manage saved albums
try await client.albums.save(["album-id"])
let savedAlbums = try await client.albums.saved()
```

### Music Catalog

```swift
// Get detailed information
let album = try await client.albums.get("album-id")
let artist = try await client.artists.get("artist-id")
let track = try await client.tracks.get("track-id")

// Batch requests for better performance
let albums = try await client.albums.several(ids: ["id1", "id2", "id3"])
let artists = try await client.artists.several(ids: ["id1", "id2", "id3"])
```

### Playlists

```swift
// Get user profile first
let profile = try await client.users.me()

// Create and manage playlists
let playlist = try await client.playlists.create(
    for: profile.id,
    name: "My Awesome Playlist",
    description: "Created with SpotifyWebAPI"
)

// Add tracks
_ = try await client.playlists.add(
    to: playlist.id,
    uris: ["spotify:track:id1", "spotify:track:id2"]
)

// Get playlist details
let fullPlaylist = try await client.playlists.get(playlist.id)
```

### Player Control

```swift
// Get current playback state
if let playback = try await client.player.state() {
    print("Now playing: \(playback.item?.name ?? "Nothing")")
    print("Device: \(playback.device?.name ?? "Unknown")")
}

// Control playback
try await client.player.resume()
try await client.player.pause()
try await client.player.skipToNext()
try await client.player.setVolume(75)
try await client.player.setShuffle(true)

// Play specific content
try await client.player.play(contextURI: "spotify:album:album-id")
try await client.player.play(uris: ["spotify:track:track-id"])
```

### Search & Discovery

```swift
// Search for content
let results = try await client.search.execute(
    query: "Queen Bohemian Rhapsody",
    types: [.track, .artist, .album],
    limit: 20
)

// Get recommendations
let recommendations = try await client.browse.getRecommendations(
    seedArtists: ["artist-id"],
    seedTracks: ["track-id"],
    targetDanceability: 0.8,
    targetEnergy: 0.7
)

// Browse categories
let categories = try await client.browse.categories()
let newReleases = try await client.browse.newReleases()
```

## 🔧 Advanced Features

### Pagination

Handle large datasets efficiently:

```swift
// Collect all pages automatically
let allPlaylists = try await client.playlists.allMyPlaylists()

// Stream items for memory efficiency
for try await item in client.playlists.streamItems("playlist_id") {
    if let track = item.track as? Track {
        print("Processing track: \(track.name)")
    }
}
```

### Error Handling

```swift
do {
    let profile = try await client.users.me()
    print("User: \(profile.displayName ?? "Unknown")")
} catch SpotifyAuthError.tokenExpired {
    // Handle expired token - library auto-refreshes when possible
    print("Token expired, attempting refresh...")
} catch let error as SpotifyAPIError {
    print("API Error: \(error.message)")
    if let statusCode = error.statusCode {
        print("Status Code: \(statusCode)")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Configuration

Customize the client behavior:

```swift
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
    ),
    networkRecoveryConfiguration: .init(
        maxRetries: 3,
        retryableStatusCodes: [500, 502, 503, 504],
        retryDelay: 1.0
    )
)

let client = SpotifyClient(authenticator: authenticator, configuration: config)
```

## 🧪 Testing

The library includes comprehensive testing utilities:

```swift
import Testing
@testable import SpotifyWebAPI

@Suite("My Tests")
struct MyTests {
    func testUserProfile() async throws {
        let mock = MockSpotifyClient()
        mock.mockProfile = CurrentUserProfile(
            id: "test-user",
            displayName: "Test User",
            // ... other properties
        )
        
        let viewModel = MyViewModel(client: mock)
        await viewModel.loadProfile()
        
        #expect(viewModel.userName == "Test User")
        #expect(mock.getUsersCalled)
    }
    
    func testErrorHandling() async throws {
        let mock = MockSpotifyClient()
        mock.mockError = SpotifyAuthError.tokenExpired
        
        // Test your error handling logic
        // ...
    }
}
```

### Test Coverage

The library maintains **100% test coverage** with:
- ✅ **520 tests** across 107 test suites
- ✅ Unit tests for all public APIs
- ✅ Integration tests with real Spotify API
- ✅ Performance tests for critical paths
- ✅ Mock implementations for testing

## 🏗️ Architecture

### Core Components

- **SpotifyClient** - Main API client with full Spotify Web API coverage
- **Authenticators** - Handle different OAuth2 flows (Authorization Code, PKCE, Client Credentials)
- **Models** - Type-safe representations of all Spotify API responses
- **Configuration** - Customizable client behavior and debugging options
- **Testing** - MockSpotifyClient and utilities for unit testing

### Design Principles

- **Type Safety** - Leverage Swift's type system to prevent runtime errors
- **Modern Concurrency** - Built with async/await and structured concurrency
- **Performance** - Request deduplication, efficient pagination, and smart caching
- **Reliability** - Comprehensive error handling and automatic retry logic
- **Testability** - Extensive mocking support and test utilities

## 📱 Platform Support

- **iOS** 13.0+
- **macOS** 10.15+
- **tvOS** 13.0+
- **watchOS** 6.0+
- **Linux** (Swift 5.9+)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Open `Package.swift` in Xcode
3. Run tests: `swift test`
4. Create a feature branch
5. Submit a pull request

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter MockSpotifyClientTests

# Run with coverage
swift test --enable-code-coverage
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Spotify Web API](https://developer.spotify.com/documentation/web-api/) for the comprehensive music platform
- The Swift community for excellent async/await and testing frameworks
- Contributors and users who help improve this library

## 📞 Support

- 📖 [Documentation](Documentation/README.md)
- 🐛 [Issue Tracker](https://github.com/your-org/SpotifyWebAPI/issues)
- 💬 [Discussions](https://github.com/your-org/SpotifyWebAPI/discussions)
- 📧 Email: support@yourorg.com

---

Made with ❤️ for the Swift and Spotify communities
# Common Patterns Guide

This guide demonstrates best practices and common patterns when using SpotifyKit in your applications.

## Table of Contents

- [Pagination Strategies](#pagination-strategies)
- [Error Handling](#error-handling)
- [Image Selection](#image-selection)
- [Rate Limiting](#rate-limiting)
- [Response Mapping](#response-mapping)
- [Testing Approaches](#testing-approaches)
- [Authentication Patterns](#authentication-patterns)

## Pagination Strategies

### Stream Individual Items

Use when you need to process items one-by-one without loading everything into memory:

```swift
// Process each track individually
for try await track in client.users.streamTopTracks(timeRange: .longTerm) {
    await processTrack(track)
}
```

### Stream Pages

Use when you need to work with batches but want memory efficiency:

```swift
// Process tracks in batches of 50
let stream = client.users.streamTopTrackPages(timeRange: .mediumTerm, pageSize: 50)
for try await page in stream {
    let trackNames = page.items.compactMap(\.name)
    await saveBatch(trackNames)
}
```

### Collect All Items

Use when you need the complete dataset and memory isn't a concern:

```swift
// Collect all saved albums
var allAlbums: [Album] = []
var offset = 0
let limit = 50

while true {
    let page = try await client.albums.saved(limit: limit, offset: offset)
    allAlbums.append(contentsOf: page.items)
    
    guard page.next != nil else { break }
    offset += limit
}
```

### Limited Collection

Use when you want a specific number of items efficiently:

```swift
// Get exactly 100 tracks from a large playlist
let stream = client.playlists.streamItems(
    playlistID,
    pageSize: 50,
    maxItems: 100
)

var tracks: [Track] = []
for try await item in stream {
    if case .track(let track) = item {
        tracks.append(track)
    }
}
```

## Error Handling

### Comprehensive Error Handling

```swift
let client: UserSpotifyClient = .pkce(...)

func fetchUserProfile() async throws -> CurrentUserProfile {
    do {
        return try await client.users.me()
    } catch let error as SpotifyClientError {
        switch error {
        case .unauthorized:
            // Token expired - refresh it
            try await refreshToken()
            return try await client.users.me()
            
        case .rateLimited(let info):
            // Wait and retry
            let delay = info.retryAfter ?? 1.0
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await fetchUserProfile()
            
        case .httpError(let statusCode, _):
            if statusCode == 503 {
                // Service unavailable - retry with backoff
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                return try await fetchUserProfile()
            }
            throw error
            
        default:
            throw error
        }
    }
}
```

## Image Selection

### Finding the Best Image

Use the `largestImage` and `smallestImage` helpers:

```swift
let album = try await client.albums.get(albumID)

// Get high-res for detail view
if let cover = album.images?.largestImage {
    imageView.load(url: cover.url)
}

// Get thumbnail for list view
if let thumbnail = album.images?.smallestImage {
    listCell.load(url: thumbnail.url)
}
```

### Finding Specific Sizes

```swift
// Find image closest to 300px
if let mediumImage = album.images?.image(closestTo: 300) {
    imageView.load(url: mediumImage.url)
}
```

## Rate Limiting

### Automatic Handling

The client handles 429 Too Many Requests automatically by default. You can configure the retry behaviour:

```swift
let config = SpotifyClientConfiguration.default
    .withMaxRateLimitRetries(3)

let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate],
    configuration: config
)
```

### Manual Monitoring

Monitor rate limits to throttle your own requests:

```swift
client.events.onRateLimitInfo { info in
    print("Requests remaining: \(info.remaining ?? 0)")
    print("Resets at: \(info.resetDate?.description ?? "unknown")")
    
    if let remaining = info.remaining, remaining < 10 {
        print("⚠️ Approaching rate limit!")
    }
}
```

## Response Mapping

### Simplifying Models

Convert complex API models into simple view models:

```swift
struct TrackViewModel {
    let title: String
    let artist: String
    let duration: String
    let coverURL: URL?
}

extension Track {
    func toViewModel() -> TrackViewModel {
        TrackViewModel(
            title: name,
            artist: artistNames ?? "Unknown Artist",
            duration: durationFormatted ?? "0:00",
            coverURL: album?.images?.smallestImage?.url
        )
    }
}
```

## Testing Approaches

### Mocking Responses

Use `SpotifyMockAPIServer` for integration tests:

```swift
let server = SpotifyMockAPIServer()
try await server.start()

let client: UserSpotifyClient = .pkce(
    clientID: "test-id",
    redirectURI: URL(string: "test://callback")!,
    scopes: [.userReadPrivate],
    configuration: .init(apiBaseURL: server.baseURL)
)

// Mock a specific endpoint
server.mock(
    .get,
    path: "/v1/me",
    response: .ok(CurrentUserProfile.mock())
)

let user = try await client.users.me()
XCTAssertEqual(user.displayName, "Mock User")
```

### Unit Testing with Protocols

Use protocols to mock the client in your app code:

```swift
protocol MusicService {
    func fetchTopTracks() async throws -> [Track]
}

class SpotifyMusicService: MusicService {
    let client: UserSpotifyClient
    
    init(client: UserSpotifyClient) {
        self.client = client
    }
    
    func fetchTopTracks() async throws -> [Track] {
        try await client.users.topTracks().items
    }
}

class MockMusicService: MusicService {
    func fetchTopTracks() async throws -> [Track] {
        [Track.mock(name: "Test Track")]
    }
}
```

## Authentication Patterns

### Token Refresh Flow

Handle token refresh events to keep your UI in sync:

```swift
// 1. Show loading state
client.events.onTokenRefreshWillStart { info in
    await MainActor.run {
        appState.isRefreshingToken = true
    }
}

// 2. Save new tokens
client.events.onTokenRefreshDidSucceed { tokens in
    await keychain.save(tokens)
    await MainActor.run {
        appState.isRefreshingToken = false
        appState.isAuthenticated = true
    }
}

// 3. Handle failure (logout)
client.events.onTokenRefreshDidFail { error in
    await MainActor.run {
        appState.isRefreshingToken = false
        appState.isAuthenticated = false
        router.showLoginScreen()
    }
}
```

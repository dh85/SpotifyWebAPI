# Common Patterns Guide

This guide demonstrates best practices and common patterns when using SpotifyWebAPI in your applications.

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
            
        case .invalidRequest(let reason):
            // Fix the request parameters
            throw AppError.invalidParameters(reason)
            
        case .notFound:
            throw AppError.userNotFound
            
        default:
            throw error
        }
    } catch {
        // Network or other errors
        throw AppError.networkError(error)
    }
}
```

### Retry Logic with Exponential Backoff

```swift
func fetchWithRetry<T>(
    maxAttempts: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch let error as SpotifyClientError {
            lastError = error
            
            switch error {
            case .rateLimited(let info):
                let delay = info.retryAfter ?? Double(attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
                
            case .unauthorized:
                // Don't retry auth errors
                throw error
                
            default:
                // Exponential backoff for other errors
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        } catch {
            lastError = error
            if attempt < maxAttempts {
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
        }
    }
    
    throw lastError ?? AppError.unknown
}
```

## Image Selection

### Choose the Best Image Size

```swift
extension [SpotifyImage] {
    /// Gets the largest available image
    var largest: SpotifyImage? {
        self.max(by: { ($0.width ?? 0) < ($1.width ?? 0) })
    }
    
    /// Gets a thumbnail (< 200px)
    var thumbnail: SpotifyImage? {
        self.first(where: { $0.isThumbnail })
    }
    
    /// Gets high-res image (>= 640px)
    var highRes: SpotifyImage? {
        self.first(where: { $0.isHighRes })
    }
    
    /// Gets closest to target width
    func closest(to targetWidth: Int) -> SpotifyImage? {
        self.min(by: {
            abs(($0.width ?? 0) - targetWidth) < abs(($1.width ?? 0) - targetWidth)
        })
    }
}

// Usage:
let artist = try await client.artists.get("artist_id")
if let imageURL = artist.images?.highRes?.url {
    // Load high-res image
} else if let imageURL = artist.images?.largest?.url {
    // Fallback to largest available
}
```

### Using Convenience Properties

```swift
// Use built-in convenience properties
let track = try await client.tracks.get("track_id")

// Primary image URL (first available image)
if let imageURL = track.album?.primaryImageURL {
    await loadImage(from: imageURL)
}

// Formatted duration
let duration = track.durationFormatted ?? "Unknown"

// Artist names
let artists = track.artistNames ?? "Unknown Artist"

print("\(track.name) by \(artists) (\(duration))")
```

## Rate Limiting

### Respecting Rate Limits

```swift
class SpotifyService {
    private let client: SpotifyClient<UserAuthCapability>
    private var lastRequestTime = Date()
    private let minimumInterval: TimeInterval = 0.1 // 10 requests/second max
    
    func fetchTrack(_ id: String) async throws -> Track {
        // Throttle requests
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minimumInterval {
            try await Task.sleep(nanoseconds: UInt64((minimumInterval - elapsed) * 1_000_000_000))
        }
        
        defer { lastRequestTime = Date() }
        return try await client.tracks.get(id)
    }
}
```

### Batch Processing with Rate Limiting

```swift
func processTracks(_ trackIDs: [String]) async throws {
    // Process in batches to respect rate limits
    let batchSize = 20
    
    for batch in trackIDs.chunked(into: batchSize) {
        // Spotify allows up to 50 IDs per request
        let tracks = try await client.tracks.several(Array(batch))
        
        for track in tracks {
            await processTrack(track)
        }
        
        // Small delay between batches
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
```

## Response Mapping

### Mapping to Custom Response Models

Pattern used in the Hummingbird server example:

```swift
// Define your response models
struct TrackResponse: Codable {
    let id: String
    let name: String
    let artists: String
    let album: String?
    let duration_ms: Int?
    let explicit: Bool
    let preview_url: String?
}

// Create mapper extensions
extension TrackResponse {
    init(from track: Track) {
        self.id = track.id ?? ""
        self.name = track.name
        self.artists = track.artistNames ?? "Unknown"
        self.album = track.album?.name
        self.duration_ms = track.durationMs
        self.explicit = track.explicit ?? false
        self.preview_url = track.previewUrl?.absoluteString
    }
}

// Use in your handlers
let track = try await client.tracks.get(trackID)
let response = TrackResponse(from: track)
return response
```

### Convenience Property Aggregation

```swift
struct PlaylistSummary {
    let name: String
    let ownerName: String
    let trackCount: Int
    let totalDuration: String
    let imageURL: URL?
}

extension PlaylistSummary {
    init(from playlist: Playlist) {
        self.name = playlist.name
        self.ownerName = playlist.ownerName ?? "Unknown"
        self.trackCount = playlist.trackCount ?? 0
        self.totalDuration = playlist.totalDurationFormatted ?? "Unknown"
        self.imageURL = playlist.primaryImageURL
    }
}
```

## Testing Approaches

### Using Mock Client

```swift
import Testing
import SpotifyWebAPI

@Test("User service fetches profile")
func testFetchProfile() async throws {
    // Create mock client
    let mockClient = MockSpotifyClient()
    
    // Setup mock data
    let mockProfile = CurrentUserProfile(
        id: "test_user",
        displayName: "Test User",
        // ... other properties
    )
    await mockClient.setMockProfile(mockProfile)
    
    // Test your service
    let service = UserService(client: mockClient)
    let profile = try await service.fetchUserProfile()
    
    #expect(profile.id == "test_user")
    #expect(await mockClient.state.getUsersCalled)
}
```

### Testing with Protocol Abstractions

```swift
// Your service uses protocol
class MusicService {
    private let spotify: SpotifyUsersAPI
    
    init(spotify: SpotifyUsersAPI) {
        self.spotify = spotify
    }
    
    func getUserTopTracks() async throws -> [Track] {
        let page = try await spotify.topTracks(timeRange: .mediumTerm, limit: 20)
        return page.items
    }
}

// Test with mock
@Test("Service fetches top tracks")
func testTopTracks() async throws {
    let mockClient = MockSpotifyClient()
    let mockTracks = Page<Track>(items: [...], total: 10, offset: 0)
    await mockClient.setMockTopTracks(mockTracks)
    
    let service = MusicService(spotify: mockClient.users)
    let tracks = try await service.getUserTopTracks()
    
    #expect(tracks.count == mockTracks.items.count)
}
```

### Testing Error Scenarios

```swift
@Test("Service handles rate limiting")
func testRateLimiting() async throws {
    let mockClient = MockSpotifyClient()
    
    // Configure mock to return rate limit error
    let rateLimitInfo = RateLimitInfo(
        limit: 100,
        remaining: 0,
        reset: Date().addingTimeInterval(60),
        retryAfter: 60
    )
    await mockClient.setMockError(.rateLimited(rateLimitInfo))
    
    let service = MusicService(spotify: mockClient.users)
    
    await #expect(throws: SpotifyClientError.rateLimited) {
        try await service.getUserTopTracks()
    }
}
```

## Authentication Patterns

### Token Refresh Flow

```swift
@MainActor
class SpotifyAuthManager: ObservableObject {
    private var client: SpotifyClient<UserAuthCapability>?
    @Published var isAuthenticated = false
    
    init() {
        setupClient()
    }
    
    private func setupClient() {
        let config = SpotifyClientConfiguration(
            clientID: "YOUR_CLIENT_ID",
            clientSecret: "YOUR_CLIENT_SECRET",
            redirectURI: URL(string: "yourapp://callback")!
        )
        
        client = SpotifyClient(configuration: config)
        
        // Setup token expiration callback
        client?.onTokenExpiration = { [weak self] in
            Task { @MainActor in
                try? await self?.refreshToken()
            }
        }
    }
    
    func authenticate() async throws {
        guard let client = client else { return }
        
        // Start authorization flow
        let authURL = client.authorizationURL(
            scopes: [.userReadPrivate, .userTopRead, .userLibraryRead]
        )
        
        // Open auth URL and get callback
        // ... handle OAuth flow ...
        
        isAuthenticated = true
    }
    
    func refreshToken() async throws {
        guard let client = client else { return }
        
        do {
            try await client.refreshToken()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            throw error
        }
    }
}
```

### Secure Token Storage

```swift
class TokenStorage {
    private let keychain = KeychainStore()
    
    func saveTokens(_ tokens: AuthorizationTokens) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tokens)
        try keychain.set(data, forKey: "spotify_tokens")
    }
    
    func loadTokens() throws -> AuthorizationTokens? {
        guard let data = try keychain.get(forKey: "spotify_tokens") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AuthorizationTokens.self, from: data)
    }
    
    func clearTokens() throws {
        try keychain.delete(forKey: "spotify_tokens")
    }
}
```

### PKCE Flow (for mobile/desktop apps)

```swift
class PKCEAuthManager {
    private let client: SpotifyClient<UserAuthCapability>
    private var codeVerifier: String?
    
    func startAuth() -> URL {
        // Generate PKCE parameters
        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier!)
        
        return client.authorizationURL(
            scopes: [.userReadPrivate, .userTopRead],
            codeChallenge: codeChallenge,
            codeChallengeMethod: .S256
        )
    }
    
    func handleCallback(code: String) async throws {
        guard let verifier = codeVerifier else {
            throw AuthError.missingVerifier
        }
        
        try await client.exchangeCodeForToken(
            code: code,
            codeVerifier: verifier
        )
        
        codeVerifier = nil
    }
    
    private func generateCodeVerifier() -> String {
        // Generate random string for PKCE
        let length = 64
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        // SHA256 hash and base64url encode
        // Implementation depends on your crypto library
        return verifier.sha256().base64URLEncoded()
    }
}
```

## Performance Tips

### Concurrent Requests

```swift
// Fetch multiple items concurrently
async let artist = client.artists.get("artist_id")
async let topTracks = client.artists.topTracks(for: "artist_id", market: "US")
async let relatedArtists = client.artists.relatedArtists(for: "artist_id")

// Wait for all to complete
let (artistData, tracks, related) = try await (artist, topTracks, relatedArtists)
```

### TaskGroup for Dynamic Concurrency

```swift
func fetchMultipleArtists(_ artistIDs: [String]) async throws -> [Artist] {
    try await withThrowingTaskGroup(of: Artist.self) { group in
        for id in artistIDs {
            group.addTask {
                try await self.client.artists.get(id)
            }
        }
        
        var artists: [Artist] = []
        for try await artist in group {
            artists.append(artist)
        }
        return artists
    }
}
```

### Caching Strategy

```swift
actor ArtistCache {
    private var cache: [String: (artist: Artist, timestamp: Date)] = [:]
    private let maxAge: TimeInterval = 300 // 5 minutes
    
    func get(_ id: String) -> Artist? {
        guard let cached = cache[id] else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) > maxAge {
            cache.removeValue(forKey: id)
            return nil
        }
        
        return cached.artist
    }
    
    func set(_ artist: Artist) {
        guard let id = artist.id else { return }
        cache[id] = (artist, Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}

class CachedSpotifyService {
    private let client: SpotifyClient<UserAuthCapability>
    private let cache = ArtistCache()
    
    func getArtist(_ id: String) async throws -> Artist {
        if let cached = await cache.get(id) {
            return cached
        }
        
        let artist = try await client.artists.get(id)
        await cache.set(artist)
        return artist
    }
}
```

---

For more examples, see:
- [Hummingbird Server Example](../Examples/HummingbirdServer/) - Complete REST API implementation
- [CLI Example](../Examples/SpotifyCLI/) - Command-line tool with ArgumentParser
- [Official Documentation](https://developer.spotify.com/documentation/web-api/) - Spotify Web API Reference

# Migration Guide

Migrating to SpotifyKit from other Spotify libraries? This guide compares common patterns and shows equivalent code.

## Overview

SpotifyKit is built with Swift 6 concurrency from the ground up, offering a modern, type-safe API for the Spotify Web API. If you're coming from other libraries, this guide will help you transition smoothly.

## Comparison with Other Libraries

### SpotifyAPI (Peter Schorn)

**Library:** [SpotifyAPI](https://github.com/Peter-Schorn/SpotifyAPI)

#### Client Initialization

**SpotifyAPI:**
```swift
let spotify = SpotifyAPI(
    authorizationManager: AuthorizationCodeFlowManager(
        clientId: "client-id",
        clientSecret: "client-secret"
    )
)
```

**SpotifyKit:**
```swift
let client: UserSpotifyClient = .authorizationCode(
    clientID: "client-id",
    clientSecret: "client-secret",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)
```

#### Getting User Profile

**SpotifyAPI:**
```swift
let profile = try await spotify.currentUserProfile()
```

**SpotifyKit:**
```swift
let profile = try await client.users.me()
```

#### Searching

**SpotifyAPI:**
```swift
let results = try await spotify.search(
    query: "Bohemian Rhapsody",
    categories: [.track]
)
```

**SpotifyKit:**
```swift
let results = try await client.search
    .query("Bohemian Rhapsody")
    .forTracks()
    .execute()
```

#### Pagination

**SpotifyAPI:**
```swift
var allTracks: [Track] = []
var page = try await spotify.library.tracks()

while true {
    allTracks.append(contentsOf: page.items)
    guard let next = page.next else { break }
    page = try await spotify.getFromHref(next)
}
```

**SpotifyKit:**
```swift
// Automatic collection
let allTracks = try await client.tracks.allSavedTracks()

// Or stream one-by-one
for try await track in client.tracks.streamSavedTracks() {
    print(track.name)
}
```

#### Playback Control

**SpotifyAPI:**
```swift
try await spotify.play(PlaybackRequest(context: .contextURI("spotify:album:...")))
try await spotify.pausePlayback()
```

**SpotifyKit:**
```swift
try await client.player.play(contextURI: "spotify:album:...")
try await client.player.pause()
```

### Spartan (Daltron)

**Library:** [Spartan](https://github.com/Daltron/Spartan)

#### Client Setup

**Spartan:**
```swift
Spartan.authorizationToken = "access-token"
```

**SpotifyKit:**
```swift
// Token management is automatic
let client: UserSpotifyClient = .pkce(
    clientID: "client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate]
)
```

#### Getting an Album

**Spartan:**
```swift
Spartan.getAlbum(id: "album-id") { album in
    print(album.name)
}
```

**SpotifyKit:**
```swift
let album = try await client.albums.get("album-id")
print(album.name)
```

#### Getting Multiple Tracks

**Spartan:**
```swift
Spartan.getTracks(ids: ["id1", "id2"]) { tracks in
    for track in tracks {
        print(track.name)
    }
}
```

**SpotifyKit:**
```swift
let tracks = try await client.tracks.several(ids: ["id1", "id2"])
for track in tracks {
    print(track.name)
}
```

### SwiftifyAPI

**Library:** [SwiftifyAPI](https://github.com/simformsolutions/SwiftifyAPI)

#### Authorization

**SwiftifyAPI:**
```swift
let auth = SPTAuth.defaultInstance()
auth?.clientID = "client-id"
auth?.redirectURL = URL(string: "myapp://callback")
```

**SpotifyKit:**
```swift
let client: UserSpotifyClient = .pkce(
    clientID: "client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate]
)
```

#### Search

**SwiftifyAPI:**
```swift
Swiftify.search(query: "Queen", type: .track) { results in
    if let tracks = results?.tracks?.items {
        print(tracks.count)
    }
}
```

**SpotifyKit:**
```swift
let results = try await client.search
    .query("Queen")
    .forTracks()
    .execute()

if let tracks = results.tracks?.items {
    print(tracks.count)
}
```

## Key Differences

### 1. Async/Await First

**Other Libraries:**
- Callback-based or Combine-first
- Manual error handling in closures

**SpotifyKit:**
```swift
// Clean async/await
do {
    let album = try await client.albums.get(id)
    print(album.name)
} catch {
    print("Error: \(error)")
}
```

### 2. Type-Safe Scopes

**Other Libraries:**
```swift
// String-based scopes
let scopes = "user-read-private playlist-modify-public"
```

**SpotifyKit:**
```swift
// Type-safe enum
let scopes: Set<SpotifyScope> = [
    .userReadPrivate,
    .playlistModifyPublic
]
```

### 3. Service Organization

**Other Libraries:**
- Flat API: `spotify.getAlbum()`, `spotify.getTrack()`

**SpotifyKit:**
```swift
// Organized by service
client.albums.get(id)
client.tracks.get(id)
client.player.play(uri: uri)
client.search.query("...").execute()
```

### 4. Automatic Token Management

**Other Libraries:**
- Manual token refresh
- Manual token storage

**SpotifyKit:**
```swift
// Automatic refresh and storage
let client: UserSpotifyClient = .pkce(...)

// Tokens are automatically refreshed and stored
let profile = try await client.users.me()
```

### 5. Built-in Pagination

**Other Libraries:**
- Manual pagination loops
- Manual next URL handling

**SpotifyKit:**
```swift
// Automatic pagination
let allAlbums = try await client.albums.allSavedAlbums()

// Or stream
for try await album in client.albums.streamSavedAlbums() {
    print(album.album.name)
}
```

### 6. Fluent Search API

**Other Libraries:**
- String-based queries only

**SpotifyKit:**
```swift
// Type-safe query builder
let results = try await client.search
    .query("rock")
    .byArtist("Queen")
    .inYear(1975...1980)
    .withGenre("rock")
    .forTracks()
    .inMarket("US")
    .execute()
```

### 7. Actor-Based Thread Safety

**Other Libraries:**
- Manual thread safety
- Potential race conditions

**SpotifyKit:**
```swift
// Thread-safe by design (Actor)
public actor SpotifyClient<Capability: Sendable> {
    // All state access is serialized
}
```

## Migration Checklist

### Step 1: Update Dependencies

**Remove old library:**
```swift
// Package.swift
.package(url: "https://github.com/Peter-Schorn/SpotifyAPI.git", ...)
```

**Add SpotifyKit:**
```swift
// Package.swift
.package(url: "https://github.com/dh85/SpotifyKit.git", from: "1.0.0")
```

### Step 2: Update Imports

**Before:**
```swift
import SpotifyWebAPI
import SpotifyAPI
```

**After:**
```swift
import SpotifyKit
```

### Step 3: Update Client Initialization

**Before (various patterns):**
```swift
let spotify = SpotifyAPI(authorizationManager: ...)
Spartan.authorizationToken = "..."
```

**After:**
```swift
let client: UserSpotifyClient = .pkce(
    clientID: "your-client-id",
    redirectURI: URL(string: "myapp://callback")!,
    scopes: [.userReadPrivate, .playlistModifyPublic]
)
```

### Step 4: Convert Callbacks to Async/Await

**Before:**
```swift
spotify.getAlbum(id: "album-id") { result in
    switch result {
    case .success(let album):
        print(album.name)
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

**After:**
```swift
do {
    let album = try await client.albums.get("album-id")
    print(album.name)
} catch {
    print("Error: \(error)")
}
```

### Step 5: Update Service Calls

**Before:**
```swift
spotify.currentUserProfile()
spotify.getAlbum(id: "...")
spotify.search(query: "...", categories: [.track])
```

**After:**
```swift
client.users.me()
client.albums.get("...")
client.search.query("...").forTracks().execute()
```

### Step 6: Update Pagination

**Before:**
```swift
var allItems: [Item] = []
var page = try await spotify.library.items()
while let next = page.next {
    allItems.append(contentsOf: page.items)
    page = try await spotify.getFromHref(next)
}
```

**After:**
```swift
// Simple collection
let allItems = try await client.items.allSavedItems()

// Or streaming
for try await item in client.items.streamSavedItems() {
    process(item)
}
```

## Common Patterns

### Pattern 1: User Profile

**Before (SpotifyAPI):**
```swift
let profile = try await spotify.currentUserProfile()
print(profile.displayName ?? "No name")
```

**After (SpotifyKit):**
```swift
let profile = try await client.users.me()
print(profile.displayName ?? "No name")
```

### Pattern 2: Save to Library

**Before (SpotifyAPI):**
```swift
try await spotify.library.saveAlbums(["id1", "id2"])
```

**After (SpotifyKit):**
```swift
try await client.albums.save(["id1", "id2"])
```

### Pattern 3: Playback Control

**Before (SpotifyAPI):**
```swift
try await spotify.play(PlaybackRequest(uris: ["spotify:track:..."]))
try await spotify.pausePlayback()
try await spotify.skipToNext()
```

**After (SpotifyKit):**
```swift
try await client.player.play(uris: ["spotify:track:..."])
try await client.player.pause()
try await client.player.skipToNext()
```

### Pattern 4: Search with Filters

**Before (SpotifyAPI):**
```swift
let results = try await spotify.search(
    query: "artist:Queen year:1975-1980",
    categories: [.track]
)
```

**After (SpotifyKit):**
```swift
let results = try await client.search
    .query("rock")
    .byArtist("Queen")
    .inYear(1975...1980)
    .forTracks()
    .execute()
```

## Benefits of Migrating

### 1. Modern Swift
- Swift 6 concurrency (Actors, Sendable)
- Structured concurrency (async/await)
- No callback hell

### 2. Better Type Safety
- Compile-time capability checking
- Type-safe scopes and enums
- Comprehensive Codable models

### 3. Improved Developer Experience
- Service-based organization
- Fluent search API
- Automatic pagination
- Built-in error recovery

### 4. Production Ready
- Automatic token refresh
- Rate limit handling
- Request deduplication
- Offline mode support

### 5. Better Testing
- Protocol-based design
- Mock client included
- Dependency injection friendly

## Need Help?

- **Documentation**: [SpotifyKit Docs](https://dh85.github.io/SpotifyKit/documentation/spotifykit)
- **Examples**: Check `Examples/SpotifyCLI` and `Examples/HummingbirdServer`
- **Issues**: [GitHub Issues](https://github.com/dh85/SpotifyKit/issues)

## Topics

### Related Guides

- <doc:AuthGuide>
- <doc:CommonPatterns>
- <doc:ErrorRecoveryGuide>

# Endpoint Coverage

`SpotifyClient` exposes every Spotify Web API surface area through dedicated service namespaces that hang directly off the client (`client.playlists`, `client.player`, etc.).

## Service Namespaces

| Capability | Entry Point | Common Calls |
| --- | --- | --- |
| Albums | `client.albums` | `several(_:)`, `saved(limit:offset:)`, `save(_:market:)`, `remove(_:market:)`. |
| Artists | `client.artists` | `get(id:)`, `topTracks(id:market:)`, `relatedArtists(id:)`, `follow(ids:)`. |
| Audiobooks & Chapters | `client.audiobooks` / `client.chapters` | `get(id:market:)`, `saved(limit:offset:)`, `streamChapters(id:)`. |
| Browse | `client.browse` | `newReleases(limit:country:)`, `featuredPlaylists(locale:country:)`, `categories(limit:locale:)`. |
| Episodes & Shows | `client.episodes` / `client.shows` | `get(id:market:)`, `saved(limit:offset:)`, `save(ids:)` / `remove(ids:)`. |
| Playlists | `client.playlists` | `createPlaylist`, `changeDetails`, `items`, `addItems`, `reorderItems`, `uploadCoverImage`. |
| Player | `client.player` | `currentPlaybackState`, `setShuffle`, `setRepeatMode`, `transferPlayback`, `queue`. |
| Search | `client.search` | `search(query:types:market:limit:)` with combined entity results. |
| Tracks & Users | `client.tracks` / `client.users` | `audioFeatures`, `saved`, `topTracks`, `topArtists`, `profile`. |

Each namespace gives you async methods and, on Apple platforms, Combine publishers. Most methods return strongly typed models (for example `Playlist` or `Paging<Track>`), while write operations return `EmptyResponse` for convenience. If you need to inspect or debug a request, every call also returns the underlying ``SpotifyRequest`` before execution.

### Async & Combine Parity

Service files now include "Combine Counterparts" callouts that point directly to the adjacent
`Service+Combine.swift` extensions. Likewise, each Combine file documents which async method it wraps
so you can jump between paradigms without guessing. Use async/await (`client.albums.get`) when you
want structured concurrency, or opt into the `getPublisher` variants for reactive pipelines—the
behaviour, validation, and instrumentation are identical either way.

## Pagination Patterns

Use any of the following helpers depending on your scenario:

- The `collectAllPages(pageSize:maxItems:fetchPage:)` helper for eagerly collecting items.
- ``PaginationStreamBuilder`` for streaming pages asynchronously with cancellation.
- Combine equivalents live alongside each service in the `Service+Combine.swift` extensions.

Requests accept `limit`, `offset`, `after`, and `before` parameters where Spotify supports them. The client enforces documented bounds (usually 1...50) before firing the HTTP call, returning ``SpotifyClientError/invalidRequest(reason:)`` when inputs violate the spec.

### Pagination Examples

**Fetching a single page:**

```swift
// Get first 20 saved albums
let page = try await client.albums.saved(limit: 20, offset: 0)
for album in page.items {
    print("\(album.name) by \(album.artistNames ?? "Unknown")")
}
```

**Streaming all pages:**

```swift
// Stream all user's top tracks for the last 6 months
let stream = client.users.streamTopTracks(timeRange: .mediumTerm, pageSize: 50)
for try await track in stream {
    print("\(track.name) - \(track.artistNames ?? "")")
}
```

**Collecting pages with limits:**

```swift
// Get up to 100 items from a playlist
let stream = client.playlists.streamItems(
    "playlist_id",
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

## Custom Endpoints

If you need an endpoint that is not yet modeled, extend `SpotifyClient` using the HTTP layer from your own module:

```swift
extension SpotifyClient {
    public func request<T: Decodable>(_ route: SpotifyRequest<T>) async throws -> T {
        try await httpClient.perform(route)
    }
}
```

This lets you keep SpotifyKit up to date while still calling beta endpoints or internal proxies.

## Common Usage Examples

### Error Handling

```swift
do {
    let track = try await client.tracks.get("track_id")
    print("Playing: \(track.name)")
} catch let error as SpotifyClientError {
    switch error {
    case .unauthorized:
        print("Token expired, refresh needed")
    case .rateLimited(let info):
        print("Rate limited, retry after \(info.retryAfter ?? 0)s")
    case .invalidRequest(let reason):
        print("Invalid request: \(reason)")
    default:
        print("Spotify error: \(error)")
    }
} catch {
    print("Network error: \(error)")
}
```

### Working with Images

```swift
// Get the best quality image available
let artist = try await client.artists.get("artist_id")
if let imageURL = artist.primaryImageURL {
    // Use imageURL to load image
}

// Or select specific size
if let images = artist.images, let largeImage = images.first(where: { $0.isHighRes }) {
    // Use largeImage.url
}
```

### Batch Operations

```swift
// Get multiple albums at once
let albumIDs = ["album1", "album2", "album3"]
let albums = try await client.albums.several(albumIDs, market: "US")

// Save multiple tracks
let trackIDs: Set<String> = ["track1", "track2", "track3"]
try await client.tracks.save(trackIDs)
```

### User's Top Content

```swift
// Get user's top artists over different time periods
let recentArtists = try await client.users.topArtists(
    timeRange: .shortTerm,  // Last 4 weeks
    limit: 10
)

let allTimeArtists = try await client.users.topArtists(
    timeRange: .longTerm,   // Several years
    limit: 10
)

// Stream all top tracks
for try await track in client.users.streamTopTracks(timeRange: .mediumTerm) {
    print("\(track.name) - \(track.durationFormatted ?? "")")
}
```

### Player Control

```swift
// Get current playback state
if let state = try await client.player.currentPlaybackState() {
    if let track = state.item {
        print("Now playing: \(track.name)")
        print("Progress: \(state.progressMs ?? 0)ms")
    }
}

// Control playback
try await client.player.pause()
try await client.player.next()
try await client.player.setShuffle(true)
try await client.player.setRepeatMode(.track)

// Add to queue
try await client.player.queue(uri: "spotify:track:track_id")
```

### Playlist Management

```swift
// Create a new playlist
let playlist = try await client.playlists.createPlaylist(
    for: "user_id",
    name: "My Awesome Mix",
    description: "Generated by my app",
    isPublic: false
)

// Add tracks
let uris = ["spotify:track:track1", "spotify:track:track2"]
try await client.playlists.addItems(uris, to: playlist.id)

// Get playlist items
let items = try await client.playlists.items(playlist.id, limit: 50)
for item in items.items {
    if case .track(let track) = item.item {
        print(track.name)
    }
}
```

### Search

```swift
// Search for tracks
let results = try await client.search.search(
    query: "Bohemian Rhapsody",
    types: [.track],
    market: "US",
    limit: 10
)

if let tracks = results.tracks?.items {
    for track in tracks {
        print("\(track.name) by \(track.artistNames ?? "")")
    }
}

// Multi-type search
let multiResults = try await client.search.search(
    query: "Queen",
    types: [.artist, .album, .track],
    market: "US"
)
```

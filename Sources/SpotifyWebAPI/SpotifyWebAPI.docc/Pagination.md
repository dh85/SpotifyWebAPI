# Pagination

Learn how to efficiently handle paginated responses from the Spotify API.

## Overview

Many Spotify endpoints return paginated results. SpotifyWebAPI provides multiple approaches for handling pagination based on your needs.

## Manual Pagination

Fetch one page at a time:

```swift
var offset = 0
let limit = 50

while true {
    let page = try await client.playlists.myPlaylists(limit: limit, offset: offset)
    
    for playlist in page.items {
        print(playlist.name)
    }
    
    guard page.next != nil else { break }
    offset += limit
}
```

## Automatic Collection

Fetch all items at once (with safety limits):

```swift
// Fetches up to 1,000 playlists by default
let playlists = try await client.playlists.allMyPlaylists()

// Fetch unlimited (use with caution)
let allPlaylists = try await client.playlists.allMyPlaylists(maxItems: nil)

// Custom limit
let playlists = try await client.playlists.allMyPlaylists(maxItems: 500)
```

## Streaming (Recommended for Large Collections)

Use AsyncStream for memory-efficient processing:

```swift
for try await item in client.playlists.streamItems("playlist_id") {
    if let track = item.track as? Track {
        print("\(track.name) by \(track.artistNames)")
    }
}
```

### Benefits of Streaming

- **Memory efficient**: Only one page in memory at a time
- **Automatic cancellation**: Stop early without fetching remaining pages
- **Progress tracking**: Process items as they arrive
- **Backpressure**: Fetches next page only when needed

## Cursor-Based Pagination

Some endpoints use cursor-based pagination:

```swift
var cursor: String? = nil

repeat {
    let page = try await client.users.followedArtists(limit: 50, after: cursor)
    
    for artist in page.items {
        print(artist.name)
    }
    
    cursor = page.cursors?.after
} while cursor != nil
```

## Performance Considerations

### Small Collections (< 100 items)
Use manual pagination or automatic collection:
```swift
let playlists = try await client.playlists.myPlaylists(limit: 50)
```

### Medium Collections (100-1,000 items)
Use automatic collection with limits:
```swift
let playlists = try await client.playlists.allMyPlaylists(maxItems: 1000)
```

### Large Collections (1,000+ items)
Use streaming for memory efficiency:
```swift
for try await playlist in client.playlists.streamMyPlaylists() {
    print(playlist.name)
}
```

## Rate Limits

Spotify enforces rate limits. SpotifyWebAPI automatically handles 429 responses with retry:

```swift
let config = SpotifyClientConfiguration(
    requestTimeout: 30,
    maxRateLimitRetries: 3  // Retry up to 3 times
)

let client = SpotifyClient.pkce(..., configuration: config)
```

## See Also

- ``SpotifyClient``
- ``Page``
- ``CursorBasedPage``
- ``SpotifyClientConfiguration``

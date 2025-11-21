# Pagination Guide

This guide explains how to handle paginated Spotify API responses efficiently.

## Quick Start

### Small Collections (< 1,000 items)

Use convenience methods with default limits:

```swift
// Get up to 1,000 playlists (default limit)
let playlists = try await client.playlists.allMyPlaylists()

// Get up to 5,000 tracks from a playlist (default limit)
let tracks = try await client.playlists.allItems("playlist_id")
```

### Medium Collections (1,000 - 5,000 items)

Explicitly set `maxItems` or use `nil` for unlimited:

```swift
// Get exactly 2,000 playlists
let playlists = try await client.playlists.allMyPlaylists(maxItems: 2000)

// Get all playlists (no limit)
let allPlaylists = try await client.playlists.allMyPlaylists(maxItems: nil)
```

## Large Collections (10,000+ items)

For very large collections (e.g., 50,000 saved tracks), implement manual pagination with:
- Progress feedback
- Cancellation support
- Error handling
- Rate limit awareness

### Pattern: Manual Pagination with Progress

```swift
func fetchAllSavedTracks(
    onProgress: @escaping (Double) -> Void
) async throws -> [SavedTrack] {
    var allTracks: [SavedTrack] = []
    var offset = 0
    let limit = 50
    
    while true {
        // Fetch one page
        let page = try await client.tracks.saved(limit: limit, offset: offset)
        allTracks.append(contentsOf: page.items)
        
        // Update progress (0.0 to 1.0)
        let progress = Double(allTracks.count) / Double(page.total)
        onProgress(progress)
        
        // Check if we're done
        guard let nextURL = page.next else { break }
        
        offset += limit
        
        // Optional: Add delay to avoid rate limits
        try await Task.sleep(for: .milliseconds(100))
    }
    
    return allTracks
}

// Usage
let tracks = try await fetchAllSavedTracks { progress in
    print("Progress: \(Int(progress * 100))%")
}
```

### Pattern: Cancellable Pagination

```swift
func fetchAllSavedTracks() async throws -> [SavedTrack] {
    var allTracks: [SavedTrack] = []
    var offset = 0
    let limit = 50
    
    while true {
        // Check for cancellation
        try Task.checkCancellation()
        
        let page = try await client.tracks.saved(limit: limit, offset: offset)
        allTracks.append(contentsOf: page.items)
        
        guard page.next != nil else { break }
        offset += limit
    }
    
    return allTracks
}

// Usage with cancellation
let task = Task {
    try await fetchAllSavedTracks()
}

// Cancel if needed
task.cancel()
```

### Pattern: AsyncStream (Recommended for Large Collections)

Use `AsyncStream` to process items as they arrive without loading everything into memory:

```swift
var totalFetched = 0
var firstPage: Page<SavedTrack>?

for try await page in client.streamPages(pageSize: 50) { limit, offset in
    try await client.tracks.saved(limit: limit, offset: offset)
} {
    if firstPage == nil {
        firstPage = page
    }
    
    totalFetched += page.items.count
    let progress = Double(totalFetched) / Double(page.total)
    updateProgress(progress)
    
    // Process items immediately
    await processTracks(page.items)
}
```

Or stream individual items:

```swift
for try await track in client.streamItems(pageSize: 50) { limit, offset in
    try await client.tracks.saved(limit: limit, offset: offset)
} {
    await processTrack(track)  // Process one at a time
}
```

**Benefits:**
- ✅ Memory efficient - one page/item at a time
- ✅ Automatic cancellation support
- ✅ Backpressure - consumer controls pace
- ✅ Progress built-in - each page is progress update

### Pattern: Incremental Loading (Recommended for UI)

Instead of loading everything upfront, load pages on-demand:

```swift
class TrackLoader: ObservableObject {
    @Published var tracks: [SavedTrack] = []
    @Published var isLoading = false
    
    private var offset = 0
    private let limit = 50
    private var hasMore = true
    
    func loadNextPage() async throws {
        guard !isLoading && hasMore else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let page = try await client.tracks.saved(limit: limit, offset: offset)
        tracks.append(contentsOf: page.items)
        
        offset += limit
        hasMore = page.next != nil
    }
}

// Usage in SwiftUI
List {
    ForEach(loader.tracks) { track in
        TrackRow(track: track)
    }
    
    if loader.hasMore {
        ProgressView()
            .onAppear {
                Task { try await loader.loadNextPage() }
            }
    }
}
```

## Performance Characteristics

| Items | Requests | Time | Memory | Recommendation |
|-------|----------|------|--------|----------------|
| 100 | 2 | 200ms | 200KB | ✅ Use convenience methods |
| 1,000 | 20 | 2s | 2MB | ✅ Use convenience methods |
| 5,000 | 100 | 10s | 10MB | ⚠️ Use maxItems or manual pagination |
| 10,000 | 200 | 20s | 20MB | ❌ Use manual pagination with progress |
| 50,000 | 1,000 | 100s | 100MB | ❌ Use incremental loading |

## Rate Limits

Spotify enforces rate limits (~180 requests/minute per user). For large collections:

1. **Add delays** between requests (100-200ms)
2. **Handle 429 errors** - The library automatically retries with `Retry-After` header
3. **Use larger page sizes** - Request 50 items per page (maximum)
4. **Implement exponential backoff** for repeated failures

## Best Practices

### ✅ DO:
- Use convenience methods for typical use cases
- Implement manual pagination for 10,000+ items
- Show progress feedback for long operations
- Support cancellation for background tasks
- Cache results when appropriate
- Use incremental loading for UI

### ❌ DON'T:
- Fetch unlimited items without user awareness
- Block the UI thread during large fetches
- Ignore rate limit errors
- Load all items upfront for large collections
- Fetch data you don't need

## Examples

### Example: Fetch First 100 Saved Tracks

```swift
let tracks = try await client.tracks.saved(limit: 50, offset: 0)
print("Fetched \(tracks.items.count) tracks")
```

### Example: Fetch All Playlists with Default Limit

```swift
let playlists = try await client.playlists.allMyPlaylists()
print("Fetched \(playlists.count) playlists (max 1,000)")
```

### Example: Fetch Unlimited Playlists

```swift
let allPlaylists = try await client.playlists.allMyPlaylists(maxItems: nil)
print("Fetched \(allPlaylists.count) playlists")
```

### Example: Manual Pagination with Error Handling

```swift
func fetchAllTracks() async throws -> [SavedTrack] {
    var allTracks: [SavedTrack] = []
    var offset = 0
    let limit = 50
    var retryCount = 0
    let maxRetries = 3
    
    while true {
        do {
            let page = try await client.tracks.saved(limit: limit, offset: offset)
            allTracks.append(contentsOf: page.items)
            
            guard page.next != nil else { break }
            offset += limit
            retryCount = 0 // Reset on success
            
        } catch {
            retryCount += 1
            if retryCount >= maxRetries {
                throw error
            }
            // Exponential backoff
            try await Task.sleep(for: .seconds(pow(2.0, Double(retryCount))))
        }
    }
    
    return allTracks
}
```

## See Also

- [Spotify Web API Pagination](https://developer.spotify.com/documentation/web-api/concepts/pagination)
- [Rate Limiting](https://developer.spotify.com/documentation/web-api/concepts/rate-limits)

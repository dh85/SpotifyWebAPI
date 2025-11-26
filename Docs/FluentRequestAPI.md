# Fluent Request API

The Fluent Request API provides a chainable, type-safe way to construct HTTP requests to the Spotify Web API.

## Overview

The `RequestBuilder` class allows you to build requests incrementally by chaining method calls, making your code more readable and maintainable compared to manually constructing `SpotifyRequest` objects.

## Basic Usage

### Simple GET Request

```swift
let album = try await client
    .get("/albums/\(albumID)")
    .market("US")
    .decode(Album.self)
```

### POST with Body

```swift
try await client
    .post("/playlists/\(playlistID)/tracks")
    .body(["uris": trackURIs])
    .execute()
```

### PUT with Query Parameters

```swift
try await client
    .put("/me/player/play")
    .query("device_id", deviceID)
    .body(["uris": trackURIs])
    .execute()
```

### DELETE with Body

```swift
try await client
    .delete("/me/albums")
    .body(IDsBody(ids: albumIDs))
    .execute()
```

## API Methods

### HTTP Method Shortcuts

The `SpotifyClient` provides convenience methods for each HTTP verb:

- `client.get(path)` - Creates a GET request builder
- `client.post(path)` - Creates a POST request builder
- `client.put(path)` - Creates a PUT request builder
- `client.delete(path)` - Creates a DELETE request builder
- `client.request(method:path:)` - Creates a request builder with any method

### RequestBuilder Methods

#### Query Parameters

**Single Parameter**
```swift
.query(name: String, value: CustomStringConvertible?)
```

Adds a single query parameter. If the value is nil, the parameter is omitted.

```swift
let tracks = try await client
    .get("/albums/\(albumID)/tracks")
    .query("market", "US")
    .query("limit", 50)
    .query("offset", 0)
    .decode(Page<SimplifiedTrack>.self)
```

**Multiple Parameters**
```swift
.query(_ items: [String: CustomStringConvertible?])
```

Adds multiple query parameters at once.

```swift
let tracks = try await client
    .get("/albums/\(albumID)/tracks")
    .query([
        "market": "US",
        "limit": 50,
        "offset": 0
    ])
    .decode(Page<SimplifiedTrack>.self)
```

**Pagination Helper**
```swift
.paginate(limit: Int, offset: Int)
```

Convenience method for adding standard pagination parameters.

```swift
let savedAlbums = try await client
    .get("/me/albums")
    .paginate(limit: 50, offset: 100)
    .decode(Page<SavedAlbum>.self)
```

**Market Helper**
```swift
.market(_ market: String?)
```

Convenience method for adding a market parameter. If nil, the parameter is omitted.

```swift
let album = try await client
    .get("/albums/\(albumID)")
    .market("GB")
    .decode(Album.self)
```

#### Request Body

```swift
.body(_ body: any Encodable & Sendable)
```

Sets the request body to the provided encodable object.

```swift
try await client
    .post("/users/\(userID)/playlists")
    .body([
        "name": "My Playlist",
        "description": "Created via API",
        "public": false
    ])
    .execute()
```

#### Execution

**Decode Response**
```swift
.decode<T: Decodable & Sendable>(_ type: T.Type) async throws -> T
```

Executes the request and decodes the response into the specified type.

```swift
let profile = try await client
    .get("/me")
    .decode(CurrentUserProfile.self)
```

**Execute Without Response**
```swift
.execute() async throws
```

Executes the request and expects no response body (or ignores it).

```swift
try await client
    .put("/me/albums")
    .body(IDsBody(ids: albumIDs))
    .execute()
```

## Comparison with Traditional Approach

### Before (Traditional)

```swift
public func get(_ id: String, market: String? = nil) async throws -> Album {
    let request = SpotifyRequest<Album>.get(
        "/albums/\(id)",
        query: makeMarketQueryItems(from: market)
    )
    return try await client.perform(request)
}
```

### After (Fluent API)

```swift
public func get(_ id: String, market: String? = nil) async throws -> Album {
    return try await client
        .get("/albums/\(id)")
        .market(market)
        .decode(Album.self)
}
```

## Real-World Examples

### Fetching User's Top Tracks

```swift
let topTracks = try await client
    .get("/me/top/tracks")
    .query("time_range", "medium_term")
    .paginate(limit: 50, offset: 0)
    .decode(Page<Track>.self)
```

### Adding Tracks to a Playlist

```swift
let trackURIs = tracks.map { $0.uri }

try await client
    .post("/playlists/\(playlistID)/tracks")
    .query("position", 0)  // Add at beginning
    .body(["uris": trackURIs])
    .execute()
```

### Searching for Artists

```swift
let searchResults = try await client
    .get("/search")
    .query([
        "q": "Radiohead",
        "type": "artist",
        "market": "US",
        "limit": 20
    ])
    .decode(SearchResults.self)
```

### Saving Albums to Library

```swift
let albumIDs: Set<String> = ["album1", "album2", "album3"]

try await client
    .put("/me/albums")
    .body(IDsBody(ids: albumIDs))
    .execute()
```

### Creating a Playlist

```swift
let playlist = try await client
    .post("/users/\(userID)/playlists")
    .body([
        "name": "Summer Vibes 2025",
        "description": "Perfect tracks for summer",
        "public": false,
        "collaborative": false
    ])
    .decode(Playlist.self)
```

### Controlling Playback

```swift
// Play specific tracks
try await client
    .put("/me/player/play")
    .query("device_id", deviceID)
    .body([
        "uris": trackURIs,
        "position_ms": 0
    ])
    .execute()

// Pause playback
try await client
    .put("/me/player/pause")
    .query("device_id", deviceID)
    .execute()

// Skip to next track
try await client
    .post("/me/player/next")
    .query("device_id", deviceID)
    .execute()
```

## Benefits

1. **Readability**: Chain methods read like natural language
2. **Type Safety**: Swift's type system ensures correct usage
3. **Flexibility**: Easy to add optional parameters conditionally
4. **Maintainability**: Less boilerplate code to maintain
5. **Discoverability**: IDE autocomplete shows available options

## Migration Guide

To migrate existing code to use the fluent API:

1. Replace `SpotifyRequest<T>.get(...)` with `client.get(...)`
2. Replace `SpotifyRequest<T>.post(...)` with `client.post(...)`
3. Replace manual query item construction with `.query()` or `.paginate()`
4. Replace `client.perform(request)` with `.decode(T.self)`
5. For void responses, replace with `.execute()`

The traditional approach is still fully supported, so you can migrate gradually.

## Thread Safety

The `RequestBuilder` is `Sendable` and immutable. Each method call returns a new instance with the modified state, making it safe to use across actor boundaries and in concurrent contexts.

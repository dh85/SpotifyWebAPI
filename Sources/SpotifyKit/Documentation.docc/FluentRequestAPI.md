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

Adds `limit` and `offset` parameters.

```swift
let page = try await client
    .get("/me/tracks")
    .paginate(limit: 20, offset: 40)
    .decode(Page<SavedTrack>.self)
```

**Market Helper**
```swift
.market(_ market: String?)
```

Adds the `market` parameter if the value is not nil.

```swift
let album = try await client
    .get("/albums/\(id)")
    .market("JP")
    .decode(Album.self)
```

#### Request Body

**Encodable Body**
```swift
.body(_ body: any Encodable & Sendable)
```

Sets the request body to the JSON representation of the provided object.

```swift
struct PlaylistDetails: Encodable {
    let name: String
    let description: String
    let public: Bool
}

try await client
    .put("/playlists/\(id)")
    .body(PlaylistDetails(name: "New Name", description: "Updated", public: false))
    .execute()
```

#### Execution

**Decode Response**
```swift
.decode<T: Decodable>(_ type: T.Type) async throws -> T
```

Executes the request and decodes the response into the specified type.

```swift
let user = try await client.get("/me").decode(CurrentUserProfile.self)
```

**Execute (No Return)**
```swift
.execute() async throws
```

Executes the request and ignores the response body (useful for 204 No Content).

```swift
try await client.put("/me/player/pause").execute()
```

## Advanced Usage

### Custom Request Builders

You can extend `RequestBuilder` to add domain-specific helpers:

```swift
extension RequestBuilder {
    func withCommonHeaders() -> Self {
        // Add custom logic here
        return self
    }
}
```

### Integration with Combine

The Fluent Request API is designed for async/await, but you can wrap it in a `Task` for Combine:

```swift
func fetchAlbumPublisher(id: String) -> AnyPublisher<Album, Error> {
    Future { promise in
        Task {
            do {
                let album = try await client
                    .get("/albums/\(id)")
                    .decode(Album.self)
                promise(.success(album))
            } catch {
                promise(.failure(error))
            }
        }
    }
    .eraseToAnyPublisher()
}
```

# ``SpotifyKit``

A strongly typed Swift toolkit for calling the Spotify Web API from your apps and services. It gives you async/await and Combine APIs, ready-made models, and pluggable authentication so you can focus on product features instead of HTTP plumbing.

## Overview

You interact with ``SpotifyClient`` plus the service namespaces you need (for example ``SpotifyClient/albums`` or ``SpotifyClient/player``). All operations are available as async methods, and Apple platforms automatically gain Combine publishers for the same endpoints.

### What You Get

- **Predictable networking**: Built-in validation for limits, paging, and ID batches before the request leaves your app.
- **End-to-end models**: Codable types for every Spotify entity so you can decode responses or seed previews without writing JSON glue. Models include convenience properties like `artistNames`, `durationFormatted`, and `primaryImageURL` for common operations.
- **Flexible auth**: Authorization Code, PKCE, and Client Credentials flows share the same client, making it easy to target mobile, desktop, and server deployments.
- **Production-ready tooling**: Configurable retries, logging hooks, and token storage strategies help you deploy safely.
- **Fluent search API**: Build complex search queries with a type-safe, chainable interface.

### Quick Examples

```swift
// Get user's top tracks
let tracks = try await client.users.topTracks(timeRange: .mediumTerm, limit: 20)
for track in tracks.items {
    print("\(track.name) - \(track.artistNames ?? "Unknown")")
}

// Fluent search API
let results = try await client.search
    .query("rock")
    .byArtist("Queen")
    .inYear(1975...1980)
    .forTracks()
    .inMarket("US")
    .execute()

// Stream paginated data
for try await track in client.users.streamTopTracks(timeRange: .longTerm) {
    print("\(track.name) (\(track.durationFormatted ?? ""))")
}
```

For comprehensive patterns and best practices, see <doc:CommonPatterns>.

## Topics

### Getting Started

- <doc:AuthGuide>
- <doc:SecurityGuide>
- <doc:NetworkSecurity>

### Consuming the API

- <doc:EndpointsGuide>
- <doc:FluentRequestAPI>
- <doc:CommonPatterns>
- <doc:CombineGuide>
- <doc:AsyncSequences>

### Data & Modeling

- <doc:ModelsGuide>

### Testing & Tooling

- <doc:TestingGuide>
- <doc:MockServerEnhancements>

### Examples

- [Hummingbird Server Example](https://github.com/dh85/SpotifyKit/tree/main/Examples/HummingbirdServer)
- [CLI Example](https://github.com/dh85/SpotifyKit/tree/main/Examples/SpotifyCLI)

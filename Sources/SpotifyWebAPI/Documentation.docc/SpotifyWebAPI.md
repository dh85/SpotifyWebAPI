# ``SpotifyWebAPI``

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

For comprehensive patterns and best practices, see the [Common Patterns Guide](../../../Docs/CommonPatterns.md).

## Topics

### Getting Started

- <doc:AuthGuide>
- <doc:SecurityGuide>

### Consuming the API

- <doc:EndpointsGuide>
- <doc:CombineGuide>

### Data & Modeling

- <doc:ModelsGuide>

### Testing & Tooling

- <doc:TestingGuide>

### Advanced Guides

For comprehensive patterns, examples, and best practices, see:
- [Common Patterns Guide](../../../Docs/CommonPatterns.md) - Pagination strategies, error handling, rate limiting, testing approaches, and more
- [Hummingbird Server Example](../../../Examples/HummingbirdServer/) - Complete REST API implementation
- [CLI Example](../../../Examples/SpotifyCLI/) - Command-line tool demonstrating all major features

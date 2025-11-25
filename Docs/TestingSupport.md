# Testing & Tooling

Treat SpotifyWebAPI as a protocol-oriented dependency so production code, previews, and unit tests can swap implementations freely.

## Core Abstractions

- `SpotifyClientProtocol` defines every service property and helper. Build your app against this protocol.
- `MockSpotifyClient` implements the protocol with closure-based overrides for each endpoint.
- `MockHTTPClient` exercises request-building logic without hitting the network.

## Fixtures & Servers

- JSON fixtures live under `Tests/Mocks`. Load them via `SpotifyTestFixtures` to keep tests short:
  ```swift
  let playlist: Playlist = SpotifyTestFixtures.playlist("main_playlist")
  ```
- `SpotifyMockAPIServer` spins up a local server backed by fixtures so integration tests can drive the real HTTP stack without contacting Spotify.

## Helper Assertions

`Tests/Support/TestHelpers.swift` contains async and Combine utilities:

- `awaitFirstValue` bridges Combine publishers into async tests.
- `assertAggregatesPages` confirms pagination helpers emit the right order of items.
- `assertLimitOutOfRange` / `assertIDBatchTooLarge` enforce validation errors consistently.
- `expectInvalidRequest` inspects `SpotifyClientError.invalidRequest` reasons and fails with contextual source locations.

## Instrumentation & Telemetry

`SpotifyClientObserver` offers a single stream of structured events (requests, responses, retries, token lifecycle, rate limits) so you no longer have to juggle multiple callbacks. Register once via `client.addObserver(_:)` and forward events into your logging or metrics pipeline:

```swift
struct MetricsObserver: SpotifyClientObserver {
  func receive(_ event: SpotifyClientEvent) {
    switch event {
    case .tokenRefreshWillStart(let info):
      metrics.increment("token.refresh.start", tags: ["reason": "\(info.reason)"])
    case .rateLimit(let info):
      metrics.recordGauge("rate.remaining", value: info.remaining ?? -1)
    default:
      break
    }
  }
}

let handle = await client.addObserver(MetricsObserver())
```

Because `SpotifyClientObserver` is `Sendable`, you can fan out to OSLog, metrics vendors, or custom tracing backends while preserving type safety and avoiding duplicate registrations.

## CI Suggestions

1. Run targeted suites (`swift test --filter PlaylistsServiceTests`) when iterating on a feature.
2. Execute repeated stress runs (20x or 100x) before merging concurrency or networking changes.
3. Collect coverage reports for `Tests/SpotifyWebAPITests/Features` to ensure new endpoints ship with matching tests.

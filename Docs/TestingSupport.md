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

## CI Suggestions

1. Run targeted suites (`swift test --filter PlaylistsServiceTests`) when iterating on a feature.
2. Execute repeated stress runs (20x or 100x) before merging concurrency or networking changes.
3. Collect coverage reports for `Tests/SpotifyWebAPITests/Features` to ensure new endpoints ship with matching tests.
